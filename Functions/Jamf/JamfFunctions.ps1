<#
.SYNOPSIS
    Functions for Jamf Backup and Restore operations.

.DESCRIPTION
    This script provides functions to obtain and manage Jamf API tokens, make API calls, download Jamf objects, format XML files, and handle file system operations.
    It uses an explicit configuration hashtable ($Config) to pass required parameters, reducing reliance on global state.

.NOTES
    Author         : Jorge Suarez
    Prerequisite   : PowerShell
    Dependencies   : Requires access to Jamf Pro API
    Version        : 0.1.1

.COMPONENT
    Jamf Pro API Integration

.ROLE
    System Administration
    Backup Management
    API Integration

.FUNCTIONALITY
    - Jamf API token management
    - API request handling
    - Object backup and restoration
    - XML file formatting
    - File system operations
#>
function Get-JamfToken {
    param (
        [string]$BaseUrl = $Config.BaseUrl,
        [string]$Username = $Config.Username,
        [string]$Password = $Config.Password,
        [string]$ClientId = $Config.ClientId,
        [string]$ClientSecret = $Config.ClientSecret
    )

    # Suppress progress bar and verbose output to avoid TUI artifacts
    $ProgressPreference = 'SilentlyContinue'
    $VerbosePreference = 'SilentlyContinue'

    if ($ClientId -and $ClientSecret) {
        $tokenUrl = "$BaseUrl/api/oauth/token"
        $body = "client_id=$ClientId&client_secret=$ClientSecret&grant_type=client_credentials"
        $headers = @{ "Content-Type" = "application/x-www-form-urlencoded" }
    } elseif ($Username -and $Password) {
        $tokenUrl = "$BaseUrl/api/v1/auth/token"
        $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Username):$Password"))
        $headers = @{
            "Authorization" = "Basic $base64Auth"
            "Accept"        = "application/json"
        }
    } else {
        throw "Must provide Username/Password."
    }

    try {
        $response = Invoke-WebRequest -Uri $tokenUrl -Method Post -Body $body -Headers $headers -UseBasicParsing
        $token = ($response.Content | ConvertFrom-Json).PSObject.Properties["access_token", "token"].Where({ $_.Value }).Value
        return $token
    } catch {
        throw "Failed to obtain token: $_"
    }
}
function Test-AndRenewAPIToken {
    param (
        [string]$BaseUrl = $Config.BaseUrl,
        [string]$ApiVersion = "v1",
        [string]$Token = $Config.Token
    )

    try {
        $response = Invoke-JamfApiCall -BaseUrl $BaseUrl -ApiVersion $ApiVersion -Endpoint "auth/keep-alive" -Method "POST" -Token $Token
        if ($response.token) {
            $Config.Token = $response.token
        } else {
            throw "No token returned from keep-alive request."
        }
    } catch {
        Write-Log "Renewing jamf token..."
        $Config.Token = Get-JamfToken -BaseUrl $BaseUrl
    }
}
function Invoke-JamfApiCall {
    param (
        [string]$BaseUrl = $Config.BaseUrl,
        [string]$ApiVersion = $Config.ApiVersion,
        [string]$Endpoint,
        [string]$Method = "GET",
        [string]$Body,
        [string]$Token = $Config.Token,
        [switch]$XML
    )

    # Suppress progress bar and verbose output to avoid TUI artifacts
    $ProgressPreference = 'SilentlyContinue'
    $VerbosePreference = 'SilentlyContinue'
    if (-not $Token) { throw "No token provided." }

    $fullUrl = Get-JamfApiUrl -BaseUrl $BaseUrl -ApiVersion $ApiVersion -Endpoint $Endpoint
    Write-Log "API Call: $Method $fullUrl"
    $contentType = if ($XML) { "application/xml" } else { "application/json" }
    $accept = if ($XML) { "text/xml" } else { "application/json" }

    $headers = @{
        "Authorization" = "Bearer $Token"
        "Content-Type"  = $contentType
        "Accept"        = $accept
    }

    $apiSplat = @{
        URI             = $fullUrl
        Method          = $Method
        Headers         = $headers
        UseBasicParsing = $true
    }
    
    if ($Body) {
        $apiSplat.Add("Body", $Body)
    }

    try {
        
        $response = Invoke-WebRequest @apiSplat

        if ($XML) {
            return  $response.Content 
        } else { 
            return ( $response.Content | ConvertFrom-Json )
        }
    } catch {
        Write-Log "API Error ($Method $fullUrl): $_" -Level Error
        throw "API Error ($Method $fullUrl): $_"
    }
}
function Get-JamfApiUrl {
    param (
        [string]$BaseUrl,
        [string]$ApiVersion,
        [string]$Endpoint
    )
    switch ($ApiVersion) {
        "v1" { "$BaseUrl/api/v1/$Endpoint" }
        "v2" { "$BaseUrl/api/v2/$Endpoint" }
        "classic" { "$BaseUrl/JSSResource/$Endpoint" }
        default { throw "Invalid ApiVersion. Use 'v1', 'v2', or 'classic'." }
    }
}
function Format-XML {
    param (
        [string]$FilePath,
        [string]$OutputPath = $FilePath
    )

    try {
        $content = Get-Content -Path $FilePath -Raw
        $cleanContent = $content -replace '[^\x09\x0A\x0D -~]', ''
        $xml = [xml]$cleanContent
        $xmlWriter = New-Object System.Xml.XmlTextWriter($OutputPath, [System.Text.Encoding]::UTF8)
        $xmlWriter.Formatting = [System.Xml.Formatting]::Indented
        $xmlWriter.Indentation = 4
        $xml.Save($xmlWriter)
        $xmlWriter.Close()
    } catch {
        Write-Error "Failed to format XML: $_"
    }
}
function Ensure-DirectoryExists {
    param (
        [string]$DirectoryPath
    )
    if (-not (Test-Path $DirectoryPath)) {
        New-Item -Path $DirectoryPath -ItemType Directory -Force | Out-Null
    }
}
function Get-SanitizedDisplayName {
    param (
        [string]$Id,
        [string]$Name
    )
    $sanitizedName = $Name -replace '[^\x30-\x39\x41-\x5A\x61-\x7A]+', '_'
    return "$Id_$sanitizedName"
}
function Download-JamfObject {
    param (
        [string]$Id,
        [string]$Resource,
        [string]$DownloadDirectory
    )

    try {
        $jamfObject = Get-JamfObject -Id $Id -Resource $Resource
        $extension = if ($Resource -eq "computer-prestages") { "json" } else { "xml" }
        $displayName = Get-SanitizedDisplayName -Id $Id -Name $jamfObject.name
        if ($jamfObject.plist) {
            $plistFilePath = Join-Path -Path $DownloadDirectory -ChildPath "$($id)_$displayName.plist"
            $jamfObject.plist | Out-File -FilePath $plistFilePath -Encoding utf8
            Format-XML -FilePath $plistFilePath
        }
        if ($jamfObject.payload) {
            $payloadFilePath = Join-Path -Path $DownloadDirectory -ChildPath "$($id)_$displayName.$extension"
            $jamfObject.payload | Out-File -FilePath $payloadFilePath -Encoding utf8
            if ($extension -eq "xml") { Format-XML -FilePath $payloadFilePath }
        }
        if ($jamfObject.script) {
            $scriptFilePath = Join-Path -Path $DownloadDirectory -ChildPath "$($id)_$displayName.sh"
            $jamfObject.script | Out-File -FilePath $scriptFilePath -Encoding utf8
        }
    } catch {
        Write-Error "Error downloading $Resource : ID $Id - $_"
    }
}
function Get-JamfObject {
    param (
        [string]$Id,
        [string]$Resource
    )

    $apiVersion = if ($Resource -eq "computer-prestages") { "v2" } else { "classic" }
    $endpoint = if ($Resource -eq "computer-prestages") { "$Resource/$Id" } else { "$Resource/id/$Id" }
    $response = Invoke-JamfApiCall -Endpoint $endpoint -Method "GET" -ApiVersion $apiVersion -XML:($apiVersion -eq "classic")

    if ($apiVersion -eq "v2") {
        return @{
            name    = $response.displayName
            payload = $response | ConvertTo-Json -Depth 5
        }
    } else {
        $xml = [xml]$response
        $payload = $xml.DocumentElement.FirstChild.payloads
        $name = $xml.SelectSingleNode("//name").InnerText
        $script = if ($Resource -eq "scripts") { $xml.SelectSingleNode("//script_contents").InnerText }
        elseif ($Resource -eq "computerextensionattributes") { $xml.SelectSingleNode("//input_type/script").InnerText }
        else { $null }
        return @{
            name    = $name
            payload = $payload
            plist   = $response 
            script  = $script
        }
    }
}
function Download-JamfObjects {
    param(
        [string]$Id,
        [string]$Resource,
        [switch]$ClearExports
    )

    $downloadDirectory = Join-Path (Get-Location) "JAMF_Backup\$Resource"

    if ($ClearExports -and (Test-Path $downloadDirectory)) { Remove-Item $downloadDirectory -Recurse -Force }
    Ensure-DirectoryExists -DirectoryPath $downloadDirectory

    if ($Id) {
        Download-JamfObject -Id $Id -Resource $Resource -DownloadDirectory $downloadDirectory
    } else {
        Write-Output "Exporting all [$resource] objects"
        $objectIds = Get-JamfObjectIds -Resource $Resource
        foreach ($objectId in $objectIds) {
            Download-JamfObject -Id $objectId -Resource $Resource -DownloadDirectory $downloadDirectory
        }
    }
}
function Get-JamfObjectIds {
    param (
        [string]$Resource
    )

    # Invoke the Jamf API call to get the response
    $apiVersion = switch ($Resource) {
        "computer-prestages" { "v2" }
        "patch-software-title-configurations" { "v2" }
        default { "classic" }
    }
    $response = Invoke-JamfApiCall -Endpoint $Resource -Method "GET" -ApiVersion $ApiVersion

    if (-not $response) {
        Write-Host "No response received for resource: $Resource" -ForegroundColor Red
        return $null
    }

    # Get the first NoteProperty from the response
    $firstProperty = $response | Get-Member -MemberType NoteProperty | Select-Object -First 1

    if (-not $firstProperty) {
        Write-Host "No NoteProperties found in response for resource: $Resource" -ForegroundColor Yellow
        return $null
    }

    # Extract the value of the first NoteProperty and get the IDs
    $objects = $response.$($firstProperty.Name)

    # Handle special case for smart groups filtering if applicable
    if ($Resource -in "computergroups", "mobiledevicegroups") {
        return ($objects | Where-Object { -not $_.is_smart }).id
    }

    # For computer-prestages, the property is 'results' with a nested structure
    if ($Resource -eq "computer-prestages") {
        return $objects.id
    }

    # Default case: return the IDs directly from the first NoteProperty
    return $objects.id
}
function Invalidate-JamfToken {
    param (
        [string]$BaseUrl = $Config.BaseUrl,
        [string]$ApiVersion = "v1",
        [string]$Token = $Config.Token
    )

    if (-not $Token) {
        Write-Host "Token is required to invalidate." -ForegroundColor Red
        return $false
    }

    try {
        $response = Invoke-JamfApiCall -BaseUrl $BaseUrl -ApiVersion $ApiVersion -Endpoint "auth/invalidate-token" -Method "POST" -Token $Token
        if ($null -eq $response) {
            Write-Host "Token successfully invalidated." -ForegroundColor Green
        } else {
            Write-Host "Unexpected response: $response" -ForegroundColor Yellow
        }
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            Write-Host "Token already invalid or unauthorized." -ForegroundColor Yellow
        } else {
            Write-Host "Failed to invalidate token: $_" -ForegroundColor Red
        }
    }
}
function Upload-JamfObject {
    [CmdletBinding()]
    param (
        # The Jamf resource name (e.g., "policies", "scripts", etc.)
        [Parameter(Mandatory = $true)]
        [string]$Resource,

        # Path to the file containing the object payload to upload.
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        # (Optional) The ID of an existing object. If provided with -Update, an update (PUT) is performed.
        [string]$Id,

        # If provided (with $Id), this switch indicates that the object should be updated rather than created.
        [switch]$Update,

        # Optional parameters that default from the configuration hashtable.
        [string]$ApiVersion = $Config.ApiVersion,
        [string]$BaseUrl = $Config.BaseUrl,
        [string]$Token = $Config.Token
    )

    # Read the payload from the file.
    try {
        $payload = Get-Content -Path $FilePath -Raw
    } catch {
        throw "Failed to read file '$FilePath': $_"
    }

    # Determine if the payload is XML or JSON by checking its first non-whitespace character.
    $trimmedPayload = $payload.TrimStart()
    $isXML = $trimmedPayload.StartsWith("<")

    # Determine the API endpoint and HTTP method based on whether this is an update or a new upload.
    if ($Update -and $Id) {
        $endpoint = "$Resource/id/$Id"
        $method = "PUT"
    } else {
        $endpoint = "$Resource/id/0"
        $method = "POST"
    }

    # Use the Invoke-JamfApiCall helper function to perform the upload.
    try {
        $params = @{
            BaseUrl    = $BaseUrl
            ApiVersion = $ApiVersion
            Endpoint   = $endpoint
            Method     = $method
            Body       = $payload
            Token      = $Token
            XML        = $isXML
        }
        $response = Invoke-JamfApiCall @params
        Write-Output "Upload successful. Response:" 
        return $response
    } catch {
        throw "Error uploading Jamf object to resource '$Resource': $_"
    }
}
function Upload-JamfObjects {
    [CmdletBinding()]
    param(
        # The Jamf resource type to upload (e.g., "policies", "scripts", etc.)
        [Parameter(Mandatory = $true)]
        [string]$Resource,

        # Directory containing the objects to upload
        [Parameter(Mandatory = $false)]
        [string]$SourceDirectory = (Join-Path (Get-Location) "JAMF_Backup/$Resource"),

        # File pattern to match (defaults to XML files)
        [Parameter(Mandatory = $false)]
        [string]$FilePattern = "*.xml",

        # If specified, only upload objects with these IDs
        [Parameter(Mandatory = $false)]
        [string[]]$Ids,

        # Whether to update existing objects
        [Parameter(Mandatory = $false)]
        [switch]$Update
    )

    # Verify source directory exists
    if (-not (Test-Path $SourceDirectory)) {
        Write-Error "Source directory not found: $SourceDirectory"
        return
    }

    # Get all files matching the pattern
    $files = Get-ChildItem -Path $SourceDirectory -Filter $FilePattern

    foreach ($file in $files) {
        # Extract ID from filename (assumes format: "ID_Name.xml")
        $idMatch = $file.BaseName -match '^(\d+)_'
        $id = if ($idMatch) { $matches[1] } else { $null }

        # Skip if we're filtering by IDs and this one isn't in the list
        if ($Ids -and $id -notin $Ids) {
            continue
        }

        Write-Host "Processing $($file.Name)..." -ForegroundColor Cyan

        try {
            $params = @{
                Resource = $Resource
                FilePath = $file.FullName
            }

            if ($Update -and $id) {
                $params['Id'] = $id
                $params['Update'] = $true
            }

            Upload-JamfObject @params
            Write-Host "Successfully uploaded $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Error "Failed to upload $($file.Name): $_"
        }
    }
}
function Invoke-GitPush {
    git add .
    $commitMessage = "Manual-Commit on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    git commit -m $commitMessage

    # Push changes to the repository
    git push origin main

    Write-Output "Changes pushed to Repo."
} # Invoke-GitPush
