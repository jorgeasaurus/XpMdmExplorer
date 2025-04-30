
# Function to add a batch request step
function Add-BatchRequestStep {
    param (
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [object]$Body = $null
    )
    return [PSCustomObject]@{
        id      = [guid]::NewGuid().ToString()
        method  = $Method
        url     = $Url
        headers = $Headers
        body    = $Body
    }
}
function Invoke-MgBatchRequest {
    # Prepare batch requests
    $BatchRequests = New-Object System.Collections.ArrayList

    # Batch request for Service Principal and its owned objects
    $null = $BatchRequests.Add((Add-BatchRequestStep -Method 'GET' -Url '/users/'))
    $null = $BatchRequests.Add((Add-BatchRequestStep -Method 'GET' -Url '/deviceManagement/managedDevices'))
    $null = $BatchRequests.Add((Add-BatchRequestStep -Method 'GET' -Url '/deviceManagement/auditEvents'))


    # Create the batch request body
    $BatchBody = [PSCustomObject]@{
        requests = $BatchRequests.ToArray()
    }

    # Convert the batch body to JSON
    $JSONBody = $BatchBody | ConvertTo-Json -Depth 5

    # Execute the batch request
    $BatchResponse = Invoke-MgGraphRequest -Method POST -Uri 'https://graph.microsoft.com/v1.0/$batch' -Body $JSONBody -ContentType 'application/json' -ErrorAction SilentlyContinue

    # Process each response in the batch 
    $Responses = $BatchResponse.responses

    if ($Responses.status -match "40*|50*") {
        $errorMessageJson = ($Responses | Where-Object status -Match "40*|50*" | Select-Object -ExpandProperty body -Unique).error.message
        Write-Host "[MgGraph Error] $(($errorMessageJson | ConvertFrom-Json).ErrorCode)"
        (($errorMessageJson | ConvertFrom-Json).Message | ConvertFrom-Json).Message -split " - " | ForEach-Object {
            Write-Host "[MgGraph Error] $_"
        }
        throw "[MgGraph Error] Batch request error"
    }
    # Here's where you handle the responses:
    # 1. Service Principal
    $usersResponse = $Responses | Where-Object { $_.id -eq $BatchRequests[0].id }
    $script:users = ($usersResponse.body).value

    # 2. Owned Objects
    $managedDevicesResponse = $Responses | Where-Object { $_.id -eq $BatchRequests[1].id }
    $script:managedDevices = ($managedDevicesResponse.body).value

    # 3. Audit Events
    $auditEventsResponse = $Responses | Where-Object { $_.id -eq $BatchRequests[2].id }
    $script:auditEvents = ($auditEventsResponse.body).value


}
function ConvertFrom-Base64 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Base64String
    )

    $bytes = [System.Convert]::FromBase64String($Base64String)
    $decodedText = [System.Text.Encoding]::UTF8.GetString($bytes)
    
    return $decodedText
}