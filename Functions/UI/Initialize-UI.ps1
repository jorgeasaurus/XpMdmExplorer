function Initialize-UI {
    [CmdletBinding()] param()

    Write-Log -Message "Initializing UI..." -Level "INFO"
    try {
        Setup-Application
        Create-Frames
        Create-Controls
        Wire-EventHandlers
        [Application]::Run()
        [Application]::Shutdown()
    } catch {
        [Application]::Shutdown()
        Write-Log -Message "UI initialization failed: $_" -Level "ERROR"
        throw
    }
}

function New-TextView {
    param (
        [View]$Frame,
        [string]$Text
    )
    $textView = [TextView]::new()
    $textView.Text = $Text
    $textView.ReadOnly = $true
    $textView.WordWrap = $true
    $textView.X = 0
    $textView.Y = 0
    $textView.Width = [Dim]::Fill()
    $textView.Height = [Dim]::Fill()
    $Frame.Add($textView)
    return $textView
}
function New-TableView {
    param (
        [View]$Frame
    )
    $tableView = [TableView]::new()
    $tableView.X = 0
    $tableView.Y = 0
    $tableView.Width = [Dim]::Fill()
    $tableView.Height = [Dim]::Fill()
    # Always show column headers
    try { $tableView.Style.AlwaysShowHeaders = $true } catch {}
    $Frame.Add($tableView)
    return $tableView
}
function Initialize-MenuBar {
    Write-Log "Initializing MenuBar"

    $script:about = @"
XpMdmExplorer, A terminal user interface for Intune and Jamf Pro. 
Copyright (c) 2025 Jorgeasaurus
This project is licensed under the MIT License.
PSVersion $($PSVersionTable.PSVersion)
"@
    $GraphMenuItemClose = [MenuItem]::new('_Quit', '', { [Application]::RequestStop() })
    $GraphMenuItemConnect = [MenuItem]::new('_Connect', '', {
            try {
                # Prompt to select Graph environment
                $envOptions = @('Global', 'USGov', 'USGovDoD', 'China', 'Germany')
                $choice = [Terminal.Gui.MessageBox]::Query(
                    'Graph Connection',
                    "Select environment:`n",
                    0,
                    $envOptions
                )
                $script:Environment = $envOptions[$choice]
                $script:statusBar.Items[4].Title = "Connecting..."; [Application]::Refresh()
                Connect-MgGraph -Environment $script:Environment -NoWelcome 3>$null 4>$null 6>$null | Out-Null
                $script:MgContext = Get-MgContext
                $script:CurrentUser = $script:MgContext | Select-Object -ExpandProperty Account
                if ($script:CurrentUser) {
                    Write-Log "Connected as $($script:CurrentUser)"
                    $script:DomainId = try {
                        (Get-MgDomain | Where-Object { $_.IsDefault }).Id
                    } catch {
                        (Get-MgBetaDomain | Where-Object { $_.IsDefault }).Id
                    }
                    $script:statusBar.Items[0].Title = "[Intune]$($script:DomainId):Connected"
                    $script:statusBar.Items[4].Title = "Ready"; 
                    [Application]::Refresh()
                } else {
                    Write-Log "No account found after connection."
                }
                [Terminal.Gui.MessageBox]::Query("XpMdm", "Successfully connected to Microsoft Graph`nAccount: $($script:CurrentUser)`n Tenant: $script:DomainId", 0, @("OK")) | Out-Null
            } catch {
                [Terminal.Gui.MessageBox]::Query("Error", "Connect-MgGraph failed: $($_.Exception.Message)", 0, @("OK")) | Out-Null
            }
        })
    $GraphMenuItemDisconnect = [MenuItem]::new('_Disconnect', '', {
            Disconnect-MgGraph
            [Terminal.Gui.MessageBox]::Query("XpMdm", "You have disconnected from Microsoft Graph.", 0, @("OK")) | Out-Null
        })
    # Show current Graph scopes
    $GraphMenuItemScopes = [MenuItem]::new('_Scopes', ' ', {
            try {
                $ctx = Get-MgContext
                if (-not $ctx) { throw "No context" }
                $scopes = $ctx | Select-Object -ExpandProperty Scopes
                $text = if ($scopes) { $scopes -join "`n" } else { "[No scopes returned]" }
                [Terminal.Gui.MessageBox]::Query('Graph Scopes', $text, 0, @('OK')) | Out-Null
            } catch {
                [Terminal.Gui.MessageBox]::ErrorQuery('Graph Error', "`nPlease connect to mgGraph from the menu.", 0, @('OK')) | Out-Null
            }
        })
    $GraphMenuBarItem = [MenuBarItem]::new('_Intune', @($GraphMenuItemConnect, $GraphMenuItemScopes, $GraphMenuItemDisconnect, $GraphMenuItemClose))
    # Jamf integration menu items
    $JamfMenuItemConnect = [MenuItem]::new('_Connect', 'Connect to Jamf API', {
            try {
                Write-Log -Message 'Jamf connect clicked' -Level 'INFO'
                # Prompt for Jamf credentials
                $script:jamfConnectOkClicked = $false
                $btnOk = [Terminal.Gui.Button]::new('OK'); $btnOk.X = 15; $btnOk.Y = 7
                $btnOk.add_Clicked({ $script:jamfConnectOkClicked = $true; [Application]::RequestStop() })
                $btnCancel = [Terminal.Gui.Button]::new('Cancel'); $btnCancel.X = 25; $btnCancel.Y = 7
                $btnCancel.add_Clicked({ [Application]::RequestStop() })

                # Build dialog window
                $dlg = [Terminal.Gui.Window] @{
                    Title  = 'Jamf API Connect'
                    Width  = 60
                    Height = 10
                    X      = [Terminal.Gui.Pos]::Center()
                    Y      = [Terminal.Gui.Pos]::Center()
                }

                # Input fields
                $lblUrl = [Terminal.Gui.Label] @{
                    Text = 'Base URL:'
                    X    = 1
                    Y    = 1
                }
                $txtUrl = [Terminal.Gui.TextField] @{
                    Text  = if ($script:Config.BaseUrl) { $script:Config.BaseUrl } else { '' }
                    X     = 15
                    Y     = 1
                    Width = 40
                }
                $lblUser = [Terminal.Gui.Label] @{
                    Text = 'Username:'
                    X    = 1
                    Y    = 3
                }
                $txtUser = [Terminal.Gui.TextField] @{
                    Text  = if ($script:Config.Username) { $script:Config.Username } else { '' }
                    X     = 15
                    Y     = 3
                    Width = 40
                }
                $lblPass = [Terminal.Gui.Label] @{
                    Text = 'Password:'
                    X    = 1
                    Y    = 5
                }
                $txtPass = [Terminal.Gui.TextField] @{
                    Text   = ''
                    X      = 15
                    Y      = 5
                    Width  = 40
                    Secret = $true
                }

                $dlg.Add($lblUrl, $txtUrl, $lblUser, $txtUser, $lblPass, $txtPass, $btnOk, $btnCancel)
                [Application]::Run($dlg)

                # If user cancelled, bail out cleanly
                if (-not $script:jamfConnectOkClicked) { return }

                # Read & validate
                $baseUrl = $txtUrl.Text.ToString()
                $username = $txtUser.Text.ToString()
                $password = $txtPass.Text.ToString()
                # If any field is blank, alert and abort
                if ([string]::IsNullOrWhiteSpace($baseUrl) -or 
                    [string]::IsNullOrWhiteSpace($username) -or 
                    [string]::IsNullOrWhiteSpace($password)) {
                    Write-Log -Message 'Jamf connect failed: missing credentials' -Level 'ERROR'
                    [Terminal.Gui.MessageBox]::ErrorQuery('Jamf Error', 'Base URL, Username, and Password are required.', 0, @('OK') ) | Out-Null
                    return
                }

                # Get token
                $token = Get-JamfToken -BaseUrl $baseUrl -Username $username -Password $password
                if (-not $token) { throw 'Empty token received.' }

                # Persist config
                if (-not $script:Config) { $script:Config = @{} }
                $script:Config.BaseUrl = $baseUrl
                $script:Config.Username = $username
                $script:Config.Password = $password
                $script:Config.Token = $token

                Write-Log -Message 'Jamf API token obtained' -Level 'INFO'
                [Terminal.Gui.MessageBox]::Query('XpMdm', "Successfully connected to Jamf.`nBase URL: $baseUrl`nUser: $username", 0, @('OK')) | Out-Null

                # Update status bar
                if ($script:statusBar -and $script:statusBar.Items.Count -ge 2) {
                    $script:statusBar.Items[1].Title = '[Jamf]Connected'
                }
                if ($script:statusBar -and $script:statusBar.Items.Count -ge 5) {
                    $script:statusBar.Items[4].Title = 'Ready'
                }

                [Application]::Refresh()
            } catch {
                Write-Log -Message "Jamf connect failed: $($_.Exception.Message)" -Level 'ERROR'
                [Terminal.Gui.MessageBox]::ErrorQuery('Jamf Error', $_.Exception.Message, 'OK') | Out-Null
                # Stop further processing to prevent unhandled exceptions
                return
            }
        })
    $JamfMenuItemDisconnect = [MenuItem]::new('_Disconnect', 'Disconnect from Jamf API', {
            try {
                # Remove existing Jamf configuration and token
                Remove-Variable -Scope Script -Name 'Config' -ErrorAction SilentlyContinue
                Remove-Variable -Scope Script -Name 'Config.Token' -ErrorAction SilentlyContinue
                Write-Log -Message 'Jamf disconnected' -Level 'INFO'
                $script:statusBar.Items[1].Title = "[Jamf]Disconnected"
                [Terminal.Gui.MessageBox]::Query('Jamf', 'Disconnected from Jamf', 0, @('OK')) | Out-Null
            } catch {
                [Terminal.Gui.MessageBox]::ErrorQuery('Jamf Error', "Disconnect failed: $($_.Exception.Message)", 'OK') | Out-Null
            }
        })
    $JamfMenuBarItem = [MenuBarItem]::new('_Jamf', @($JamfMenuItemConnect, $JamfMenuItemDisconnect))

    $MenuItemAbout = [MenuItem]::new('_About', ' ', {
            [Terminal.Gui.MessageBox]::Query('About', $script:about, 0, @('OK')) | Out-Null
        })
    $MenuItem3 = [MenuItem]::new('_Documentation', '', { Start-Process 'https://github.com/jorgeasaurus' })
    $MenuBarItem2 = [MenuBarItem]::new('_Help', @($MenuItemAbout, $MenuItem3))
    # Theme selection menu
    $themeLight = [MenuItem]::new('_Light', 'Light theme', { Set-Theme 'Light' })
    $themeDark = [MenuItem]::new('_Dark', 'Dark theme', { Set-Theme 'Dark' })
    $themePS = [MenuItem]::new('_PowerShell', 'PowerShell theme', { Set-Theme 'PowerShell' })
    $themeGreen = [MenuItem]::new('_Green', 'Retro theme', { Set-Theme 'Green' })
    $themeRed = [MenuItem]::new('_Red', 'Red theme', { Set-Theme 'Red' })
    $menuThemes = [MenuBarItem]::new('_Themes', @($themeLight, $themeDark, $themePS, $themeGreen, $themeRed))
    return [Terminal.Gui.MenuBar]::new(@($GraphMenuBarItem, $JamfMenuBarItem, $menuThemes, $MenuBarItem2))
}
function Initialize-StatusBar {
    param(
        [string]$ver,
        [string]$status = 'Ready'
    )

    # Intune connection status
    $intuneConnectionStatus = if (Get-MgContext) {
        $script:DomainId = try {
            (Get-MgDomain | Where-Object { $_.IsDefault }).Id
        } catch {
            (Get-MgBetaDomain | Where-Object { $_.IsDefault }).Id
        }
        "[Intune]$($script:DomainId):Connected"
    } else {
        "[Intune]Not Connected"
    }
    # Jamf connection status
    if ($script:Config -and $script:Config.Token) {
        $jamfConnectionStatus = "[Jamf]Connected"
    } else {
        $jamfConnectionStatus = "[Jamf]Not Connected"
    }

    $StatusBar = [StatusBar]::New(
        @(
            [StatusItem]::New([Key]::Null, $intuneConnectionStatus , { }),
            [StatusItem]::New([Key]::Null, $jamfConnectionStatus , { }),
            [StatusItem]::New([Key]::Null, 'ESC to quit', { }),
            [StatusItem]::New([Key]::Null, "v$ver", { }),
            [StatusItem]::New([Key]::Null, $status, { })
        )
    )

    return $StatusBar
}
function New-Button {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)][string] $Text,
        [Parameter(Mandatory)][scriptblock] $Action,
        [Parameter(Mandatory)] $X,
        [Parameter(Mandatory)] $Y,
        [int] $Width = 10
    )

    # Create and configure the Button
    $button = [Terminal.Gui.Button]::new($Text)
    $button.X = $X
    $button.Y = $Y
    $button.Width = $Width

    # Attach the click action
    $button.add_Clicked($Action)

    return $button
}
function Set-Theme($theme) {
    Write-Log "Switching theme to $theme"
    switch ($theme) {
        'Light' { $bg = [Terminal.Gui.Color]::White; $fg = [Terminal.Gui.Color]::Blue }
        'Dark' { $bg = [Terminal.Gui.Color]::Black; $fg = [Terminal.Gui.Color]::White }
        'PowerShell' { $bg = [Terminal.Gui.Color]::Blue; $fg = [Terminal.Gui.Color]::White }
        'Green' { $bg = [Terminal.Gui.Color]::Black; $fg = [Terminal.Gui.Color]::Green }
        'Red' { $bg = [Terminal.Gui.Color]::Black; $fg = [Terminal.Gui.Color]::Red }
        default { return }
    }
    $attr = [Terminal.Gui.Attribute]::Make($fg, $bg)
    $cs = [Terminal.Gui.ColorScheme]::new()
    $cs.Normal = $attr
    $cs.Focus = $attr
    $cs.HotFocus = $attr
    $cs.HotNormal = $attr
    $cs.Disabled = [Terminal.Gui.Attribute]::Make($bg, $fg)
    # Apply color scheme to main window
    if ($script:Window) { $script:Window.ColorScheme = $cs }
    # Apply to all frames
    foreach ($frame in @(
            $script:intuneCategoriesFrame,
            $script:categoriesActionsFrame,
            $script:subCategoriesFrame,
            $script:itemsFrame,
            $script:detailsFrame
        )) {
        if ($frame) { $frame.ColorScheme = $cs }
    }
    # Apply to controls
    foreach ($ctrl in @(
            $script:CategoriesListView,
            $script:SubCategoriesListView,
            $script:ItemsTableView,
            $script:DetailsTextView,
            $script:btnExport,
            $script:MenuBar,
            $script:statusBar
        )) {
        if ($ctrl) { $ctrl.ColorScheme = $cs }
    }
    [Application]::Refresh()
}
