function Create-Controls {
    # Splat parameters for the Export button
    $btnExportParams = @{
        Text   = 'Export'
        X      = $script:categoriesActionsFrame.X + 2
        Y      = [Pos]::Top($script:categoriesActionsFrame) + 2
        Width  = 10
        Action = {
            Write-Log "Export button clicked"
            try {
                # Determine selected index
                if ($script:ItemsTableView) {
                    $idx = $script:ItemsTableView.SelectedRow
                } else {
                    $idx = $script:ItemsListView.SelectedItem
                }
                if ($idx -lt 0) {
                    [Terminal.Gui.MessageBox]::ErrorQuery("Export Error", "No item selected.", "OK") | Out-Null
                    return
                }
                # Choose raw item if available, otherwise filtered
                if ($null -ne $global:RawItems -and $idx -lt $global:RawItems.Count) {
                    $exportItem = $global:RawItems[$idx]
                } elseif ($idx -lt $global:CurrentItems.Count) {
                    $exportItem = $global:CurrentItems[$idx]
                } else {
                    [Terminal.Gui.MessageBox]::ErrorQuery("Export Error", "Invalid item index.", "OK") | Out-Null
                    return
                }
                $category = $script:CurrentCategory
                # Derive identifier from Id or id property if present
                if ($exportItem.PSObject.Properties["Id"]) {
                    $id = $exportItem.Id
                } elseif ($exportItem.PSObject.Properties["id"]) {
                    $id = $exportItem.id
                } else {
                    $id = (Get-Date).ToString("yyyyMMdd_HHmmss")
                }
                # Prompt user for export path via SaveDialog
                $SaveDialog = [SaveDialog]::New()
                # Set dialog title and default directory
                $SaveDialog.Title = "Export Items"
                $SaveDialog.CanCreateDirectories = $true
                $SaveDialog.DirectoryPath = $HOME
                # Attempt to prefill default filename (include MDM source, category, and id)
                try {
                    $SaveDialog.FilePath = "$($script:CurrentMdm)-$($category)-$($id)" -replace(" ", "_")
                } catch {
                    Write-Log -Message "Unable to prefill SaveDialog filename: $($_.Exception.Message)" -Level "WARN"
                }
                # Only allow JSON files for export
                $SaveDialog.AllowedFileTypes = @(".json")
                # Show the save dialog
                [Application]::Run($SaveDialog)
                if ($SaveDialog.Canceled -or -not $SaveDialog.FilePath) { return }
                $exportPath = $SaveDialog.FilePath.ToString()
                # Export single selected item as JSON
                $exportItem | ConvertTo-Json -Depth 10 | Set-Content -Path $exportPath -Force
                Write-Log "Exported $category item(s) to $exportPath"
                [Terminal.Gui.MessageBox]::Query("Export Complete", "`nExported to:`n$exportPath", 0, @("OK")) | Out-Null
            } catch {
                Write-Log "Export failed: $($_.Exception.Message)" "ERROR"
                [Terminal.Gui.MessageBox]::ErrorQuery("Export Failed", "`nAn error occurred:`n$($_.Exception.Message)", "OK") | Out-Null
            }
        }
    }

    $script:btnExport = New-Button @btnExportParams

    # Menu & Status
    $script:MenuBar = Initialize-MenuBar
    $script:statusBar = Initialize-StatusBar -ver $script:ScriptVer

    # ListViews
    # Splat parameters for CategoriesListView
    $categoriesListViewParams = @{
        Frame = $script:intuneCategoriesFrame
        Items = @("Home", "Devices", "Apps", "Reports" , "Users", "Groups")
    }
    $script:CategoriesListView = New-ListView @categoriesListViewParams
    
    $jamfCategoriesListViewParams = @{
        Frame = $script:jamfCategoriesFrame
        Items = @("Computers", "Mobile Devices", "Jamf Users","Accounts","Settings")
    }
    $script:JamfCategoriesListView = New-ListView @jamfCategoriesListViewParams
    $script:SubCategoriesListView = New-ListView -Frame $script:subCategoriesFrame -Items @()

    # Table & Text
    $script:ItemsTableView = New-TableView -Frame $script:itemsFrame
    $script:ItemsTableView.Y = 0
    $script:ItemsTableView.Height = [Dim]::Fill() - 1

    # Initialize details pane
    $script:DetailsTextView = New-TextView -Frame $script:detailsFrame -Text ""

    # Finally add all controls to the main window and add it to the application
    $script:Window.Add(
        $script:MenuBar,
        $script:intuneCategoriesFrame,
        $script:jamfCategoriesFrame,
        $script:categoriesActionsFrame,
        $script:subCategoriesFrame,
        $script:itemsFrame,
        $script:detailsFrame,
        $script:btnExport,
        $script:statusBar
    )
    # Add the main window (script:Window) to the top-level container
    [Application]::Top.Add($script:Window)
}