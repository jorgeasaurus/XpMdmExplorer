# Populate-Items Scaffold
# Populates items based on selected subcategory.
<#
.SYNOPSIS
    Populates the items list based on the selected subcategory.

.DESCRIPTION
    Checks the command mapping for the subcategory and displays
    the subcategory as an item if a Graph command is mapped.
#>
function Populate-Items {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$SubCategory
    )

    Write-Log -Message "Populating items for subcategory: $SubCategory" -Level "INFO"
    # remember current subcategory
    $script:CurrentSubCategory = $SubCategory

    # fetch items from Graph if mapping exists
    if ($Global:intuneCommandMappings.Contains($script:CurrentCategory) -and
        $Global:intuneCommandMappings[$script:CurrentCategory].Contains($SubCategory)) {
        $uri = $Global:intuneCommandMappings[$script:CurrentCategory][$SubCategory]
        Write-Log -Message "Calling Graph URI: [$uri]" -Level "INFO"
        try {
            $script:statusBar.Items[4].Title = "Source URI: [$uri]"
            $script:statusBar.SetNeedsDisplay()
            [Application]::Refresh()
            # retrieve all pages of results (full raw data)
            try {
                if ($script:CurrentCategory -eq 'Reports') {
                    $rawFull = Get-MgDeviceReport -report $SubCategory -ErrorAction Stop
                } else { $rawFull = Invoke-MgGraphRequest -Uri $uri -Method GET -ErrorAction Stop | Get-MgGraphAllPages -ToPSCustomObject }

            } catch {
                $msg = $_.Exception.Message
                [Terminal.Gui.MessageBox]::ErrorQuery('Graph API Call Error', "`n$msg", 0, @('OK')) | Out-Null
            }
            # Store unmodified raw items
            $global:RawItems = @($rawFull)
            # Log raw Graph API response for debugging
            try {
                $rawJson = $rawFull | ConvertTo-Json -Depth 5
            } catch {
                $rawJson = '<unable to serialize rawFull>'
            }
            Write-Log -Message "Raw Graph response for '$($script:CurrentCategory) -> $SubCategory': $rawJson" -Level "DEBUG"
            # Apply property filtering for the display version
            switch ($script:CurrentCategory) {
                'Devices' {
                    switch ($SubCategory) {
                        'Device Categories' {
                            # Include id for mapping and select relevant device category properties
                            $rawItems = $rawFull | Select-Object displayName, description, platform, osVersion
                        }
                        'Device Configuration' {
                            # Include id for mapping and select relevant device configuration properties
                            $rawItems = $rawFull | Select-Object displayName, @{
                                Name       = 'Platform'
                                Expression = { $_.'@odata.type' -replace '#microsoft.graph.' }
                            }, createdDateTime, lastModifiedDateTime
                        }
                        'Device Compliance' {
                            # Include id for mapping and select relevant device compliance properties
                            $rawItems = $rawFull | Select-Object displayName, description, @{
                                Name       = 'Platform'
                                Expression = { $_.'@odata.type' -replace '#microsoft.graph.' }
                            }, createdDateTime, lastModifiedDateTime
                        }
                        'Settings Catalog' {
                            # Include id for mapping and select relevant settings catalog properties
                            $rawItems = $rawFull | Select-Object name, platforms, createdDateTime, lastModifiedDateTime
                        }
                        'Device Filters' {
                            # Include id for mapping and select relevant device filter properties
                            $rawItems = $rawFull | Select-Object displayName, platform, assignmentFilterManagementType, createdDateTime, lastModifiedDateTime
                        }
                        'Conditional Access' {
                            # Include id for mapping and select relevant conditional access properties
                            $rawItems = $rawFull | Select-Object displayName, createdDateTime, modifiedDateTime
                        }
                        'Platform Scripts' {
                            # Include id for mapping and select relevant platform script properties
                            $rawItems = $rawFull | Select-Object displayName, fileName, createdDateTime, lastModifiedDateTime
                        }
                        'Remediation Scripts' {
                            # Include id for mapping and select relevant remediation script properties
                            $rawItems = $rawFull | Select-Object displayName, Publisher, createdDateTime, lastModifiedDateTime, runasAccount
                        }
                        default {
                            # Include id for mapping and select relevant device properties
                            $rawItems = $rawFull | Select-Object deviceName, manufacturer, operatingSystem, osVersion, complianceState, managedDeviceOwnerType, userPrincipalName
                        }
                    }
                }
                'Users' {
                    # Include id for mapping and select relevant user properties
                    $rawItems = $rawFull | Select-Object displayName, userPrincipalName, accountEnabled, Department, jobTitle, createdDateTime, lastSignInDateTime
                    switch ($SubCategory) {
                        'Audit Logs' {
                            # Include id for mapping and select relevant audit log properties
                            $rawItems = $rawFull | Select-Object  activityDateTime, activityType, activityResult, category
                        }
                        'Sign-in Logs' {
                            # Include id for mapping and select relevant sign-in log properties
                            $rawItems = $rawFull | Select-Object userPrincipalName, appDisplayName, clientAppUsed, deviceDetail, ipAddress, location
                        }
                    }
                }
                'Groups' {
                    # Include id for mapping and select relevant group properties
                    $rawItems = $rawFull | Select-Object displayName, description, mailEnabled, mailNickname, securityEnabled
                }
                'Apps' {
                    # Include id for mapping and select relevant application properties
                    $rawItems = $rawFull | Select-Object DisplayName, Publisher, @{
                        Name       = 'Platform'
                        Expression = { $_.'@odata.type' -replace '#microsoft.graph.' }
                    }, lastModifiedDateTime
                    switch ($SubCategory) {
                        'Windows' {
                            # Include id for mapping and select relevant Windows app properties
                            $rawItems = $rawItems | Where-Object Platform -Match 'win'
                        }
                        'iOS/iPadOS' {
                            # Include id for mapping and select relevant iOS/iPadOS app properties
                            $rawItems = $rawItems | Where-Object Platform -Match 'ios'
                        }
                        'macOS' {
                            # Include id for mapping and select relevant macOS app properties
                            $rawItems = $rawItems | Where-Object Platform -Match 'mac'
                        }
                        'Android' {
                            # Include id for mapping and select relevant Android app properties
                            $rawItems = $rawItems | Where-Object Platform -Match 'android'
                        }
                        'App Configuration' {
                            # Include id for mapping and select relevant app configuration properties
                            $rawItems = $rawFull | Select-Object displayName, version, createdDateTime, lastModifiedDateTime
                        } 
                        'Managed App Configuration' {
                            # Include id for mapping and select relevant managed app configuration properties
                            $rawItems = $rawFull | Select-Object displayName, description, createdDateTime, lastModifiedDateTime
                        }
                        'App Categories' {
                            # Include id for mapping and select relevant app category properties
                            $rawItems = $rawFull | Select-Object displayName, id, lastModifiedDateTime
                        }
                        'App Protection Policies' {
                            # Include id for mapping and select relevant app protection policy properties
                            $rawItems = $rawFull | Select-Object displayName, @{
                                Name       = '@odata.type'
                                Expression = { $_.'@odata.type' -replace '#microsoft.graph.' }
                            }, createdDateTime, lastModifiedDateTime
                        }
                        'Discovered Apps' {
                            # Include id for mapping and select relevant discovered app properties
                            $rawItems = $rawFull | Select-Object displayName, publisher, version, deviceCount, Platform
                        }
                    }
                }
                Default {
                    # No property filtering; use all properties
                    $rawItems = $rawFull
                }
            }
            # Log the returned Jamf items for debugging
            try {
                $itemsJson = $rawItems | ConvertTo-Json -Depth 5
            } catch {
                $itemsJson = "<unable to serialize items>"
            }
            Write-Log -Message "Returned Intune items for '$($script:CurrentCategory) -> $SubCategory'" -Level "INFO"
        } catch {
            $msg = $_.Exception.Message
            if ($msg -match 'Call Connect-MgGraph' -or $msg -match 'Authentication needed') {
                [Terminal.Gui.MessageBox]::Query("Graph Error", "`nPlease connect to mgGraph from the menu.", 0, @('Ok')) | Out-Null
            }
            Write-Log -Message "Error retrieving items: $msg" -Level "ERROR"
            $rawItems = @()
        }
        # Store filtered and current items for Graph display
        $global:CurrentItems = $global:FilteredItems = @($rawItems)
    } elseif ($Global:jamfCommandMappings.Contains($script:CurrentCategory) -and
        $Global:jamfCommandMappings[$script:CurrentCategory].Contains($SubCategory)) {
        # Handle Jamf Pro API calls
        $uri = $Global:jamfCommandMappings[$script:CurrentCategory][$SubCategory]
  
        Write-Log -Message "Calling Jamf Pro URI: [$uri]" -Level "INFO"
        $script:statusBar.Items[4].Title = "Source URI: [$uri]"

        switch -Regex ($uri) {
            '/JSSResource/' {
                $uri = $uri -replace '/JSSResource/'
                $apiVersion = 'classic'
                break
            }
            '/api/v1/' {
                $uri = $uri -replace '/api/v1/'
                $apiVersion = 'v1'
                break
            }
            '/api/v2/' {
                $uri = $uri -replace '/api/v2/'
                $apiVersion = 'v2'
                break
            }
        }
        # Store URI and API version for detail lookups
        $script:JamfUri = $uri
        $script:JamfApiVersion = $apiVersion
        try {
            $script:statusBar.SetNeedsDisplay()
            [Application]::Refresh()
            # retrieve all pages of results (full raw data)
            try {
                Test-AndRenewAPIToken
                $script:statusBar.Items[1].Title = '[Jamf]:Connected'
                [Application]::Refresh()
                # Retrieve full raw data from Jamf API
                $rawFull = Invoke-JamfApiCall -Endpoint $uri -apiVersion $apiVersion -Method GET -ErrorAction Stop
                # Unwrap wrapper object if it contains a single array property
                $arrayProps = $rawFull.PSObject.Properties | Where-Object { $_.Value -is [System.Array] }
                if ($arrayProps.Count -eq 1) {
                    $rawItemsUnwrapped = $arrayProps[0].Value
                    Write-Log -Message "Unwrapped Jamf response property '$($arrayProps[0].Name)' with $($rawItemsUnwrapped.Count) items" -Level "DEBUG"
                } else {
                    Write-Log -Message "No unwrapping needed for Jamf response with $($rawFull.Count) items" -Level "DEBUG"
                    $rawItemsUnwrapped = @($rawFull)
                }
            } catch {
                $msg = $_.Exception.Message
                [Terminal.Gui.MessageBox]::ErrorQuery('Jamf API Call Error', "`n$msg", 0, @('OK')) | Out-Null
                $rawItemsUnwrapped = @()
            }
            # Store unmodified raw items
            $global:RawItems = $rawItemsUnwrapped
            # Use filtered items for display and actions
            $global:CurrentItems = $global:FilteredItems = @($rawItems)
            # Apply property filtering for the display version
            switch ($script:CurrentCategory) {
                'Computers' {
                    switch ($SubCategory) {
                        'Inventory' {
                            # Log the items for this Computers->Inventory case
                            try {
                                $itemsJson = $rawItems | ConvertTo-Json -Depth 5
                            } catch {
                                $itemsJson = '<unable to serialize rawItems>'
                            }
                            Write-Log -Message "Returned Jamf items for '$($script:CurrentCategory) -> $SubCategory': $itemsJson" -Level "INFO"
                        }
                    }
                }
                'Accounts' {
                    switch ($SubCategory) {
                        'Users' {
                            try {
                                $itemsJson = $rawFull.accounts.users | ConvertTo-Json -Depth 5
                                $global:FilteredItems = $rawFull.accounts.users
                            } catch {
                                $itemsJson = '<unable to serialize rawItems>'
                            }
                        }
                        'Groups' {
                            try {
                                $itemsJson = $rawFull.accounts.groups | ConvertTo-Json -Depth 5
                                $global:FilteredItems = $rawFull.accounts.groups
                            } catch {
                                $itemsJson = '<unable to serialize rawItems>'
                            }
                        }
                    }
                }
                default {
                    # No property filtering; use all properties
                    $rawItems = $rawItemsUnwrapped
                    $itemsJson = $rawItems | ConvertTo-Json -Depth 5

                }
            }
        } catch {
            $msg = $_.Exception.Message
            [Terminal.Gui.MessageBox]::Query("Jamf Pro Error", "`n$msg.", 0, @('Ok')) | Out-Null
          
            Write-Log -Message "Error retrieving items: $msg" -Level "ERROR"
            $rawItems = @()
        }

        Write-Log -Message "Returned Jamf items for '$($script:CurrentCategory) -> $SubCategory'" -Level "INFO"
        # For Accounts (Users/Groups), replace raw and current items with filtered list so details have an id
        if ($script:CurrentMdm -eq 'Jamf' -and $script:CurrentCategory -eq 'Accounts') {
            $global:RawItems = $global:FilteredItems
            $global:CurrentItems = $global:FilteredItems
        }

        <# Action when this condition is true #>
    } else {
        $rawItems = @()
    }



    # Display items in table view if available, otherwise list view
    if ($script:ItemsTableView) {
        # Bind filtered items to the table view
        try {
            Write-Log -Message "Binding filtered items to table view" -Level "DEBUG"
            $dt = $global:FilteredItems | ConvertTo-DataTable
            $script:ItemsTableView.Table = $dt
            # Auto-select first row and show its full raw JSON details
            if ($null -ne $global:RawItems -and $global:RawItems.Count -gt 0) {
                $script:ItemsTableView.SelectedRow = 0
                $script:DetailsTextView.Text = ($global:RawItems[0] | ConvertTo-Json -Depth 10)
            } else {
                $script:DetailsTextView.Text = ''
            }
        } catch {
            Write-Log -Message "Failed to bind filtered items to table: $($_.Exception.Message)" -Level "ERROR"
        }
    } else {
        # Fallback: show labels for filtered items
        $labels = @( $global:FilteredItems | ForEach-Object {
                if ($_.PSObject.Properties.Name -contains 'displayName') { $_.displayName }
                elseif ($_.PSObject.Properties.Name -contains 'deviceName') { $_.deviceName }
                elseif ($_.PSObject.Properties.Name -contains 'Name') { $_.Name }
                elseif ($_.PSObject.Properties.Name -contains 'id') { $_.id }
                else { ($_ | ConvertTo-Json -Depth 1) }
            } )
        $script:ItemsListView.SetSource($labels)
        # Auto-select first item and show its details
        if ($global:FilteredItems.Count -gt 0) {
            $script:ItemsListView.SelectedItem = 0
            $script:DetailsTextView.Text = ($global:FilteredItems[0] | ConvertTo-Json -Depth 10)
        } else {
            $script:DetailsTextView.Text = ''
        }
    }
}