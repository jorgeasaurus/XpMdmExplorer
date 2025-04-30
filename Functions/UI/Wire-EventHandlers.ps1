function Wire-EventHandlers {
    Write-Log -Message "Wiring up event handlers..." -Level "INFO"
    # Wire up menu bar
    $script:CategoriesListView.add_SelectedItemChanged({
            $script:CurrentCategory = $script:CategoriesListView.Source.ToList()[$script:CategoriesListView.SelectedItem]
            $script:CurrentMdm = "Intune"
            Write-Log -Message "Selected Category: $script:CurrentCategory (MDM: $script:CurrentMdm)" -Level "DEBUG"
            # Update subcategories frame title to reflect current category
            $script:subCategoriesFrame.Title = "$($script:CurrentCategory) | Overview"
            $script:subCategoriesFrame.SetNeedsDisplay()
            # Reset items frame title when category changes
            $script:itemsFrame.Title = "Items"
            $script:itemsFrame.SetNeedsDisplay()
            [Application]::Refresh()
            Populate-SubCategories -Category $script:CurrentCategory
        })
    # Wire up Jamf category selection event
    $script:JamfCategoriesListView.add_SelectedItemChanged({
            $script:CurrentCategory = $script:JamfCategoriesListView.Source.ToList()[$script:JamfCategoriesListView.SelectedItem]
            $script:CurrentMdm = "Jamf"
            Write-Log -Message "Selected Jamf Category: $script:CurrentCategory (MDM: $script:CurrentMdm)" -Level "DEBUG"
            # Update subcategories frame title to reflect current category
            $script:subCategoriesFrame.Title = "$($script:CurrentCategory) | Overview"
            $script:subCategoriesFrame.SetNeedsDisplay()
            # Reset items frame title when category changes
            $script:itemsFrame.Title = "Items"
            $script:itemsFrame.SetNeedsDisplay()
            [Application]::Refresh()
            Populate-SubCategories -Category $script:CurrentCategory
        })

    # Wire up SubCategory selection event
    $script:SubCategoriesListView.add_SelectedItemChanged({
            $script:SelectedSubCat = $script:SubCategoriesListView.Source.ToList()[$script:SubCategoriesListView.SelectedItem]
            Write-Log -Message "Selected Subcategory: $script:SelectedSubCat" -Level "DEBUG"
            if ($script:SelectedSubCat -match '---') { return }
            Populate-Items -SubCategory $script:SelectedSubCat
            # Update items frame title to reflect current subcategory
            $script:itemsFrame.Title = "$($script:CurrentSubCategory)"
            $script:itemsFrame.SetNeedsDisplay()
            [Application]::Refresh()
        })

    # Wire up table selection to show details of the selected item (Graph or Jamf)
    $script:ItemsTableView.Add_SelectedCellChanged({
            $row = $script:ItemsTableView.SelectedRow
            Write-Log -Message "Selected Row: $row" -Level "DEBUG"
            if ($row -ge 0) {
                if ($null -ne $global:RawItems -and $row -lt $global:RawItems.Count) {
                    $item = $global:RawItems[$row]
                } elseif ($row -lt $global:CurrentItems.Count) {
                    $item = $global:CurrentItems[$row]
                } else {
                    return
                }
                if ($script:CurrentMdm -eq 'Jamf') {
                    try {
                        Test-AndRenewAPIToken
                        if ($item.PSObject.Properties['id']) { $id = $item.id }
                        elseif ($item.PSObject.Properties['Id']) { $id = $item.Id }
                        else { throw "Item has no id property." }
                        switch ($script:CurrentCategory) {
                            'Accounts' {
                                switch ($script:SelectedSubCat) {
                                    'Users' {
                                        $script:statusBar.Items[4].Title = "Source URI: [$($script:JamfUri)/accounts/userid/$id]"
                                        $detail = Invoke-JamfApiCall -Endpoint "$($script:JamfUri)/userid/$id" -apiVersion $script:JamfApiVersion -Method GET -ErrorAction Stop

                                    }
                                    'Groups' {
                                        $script:statusBar.Items[4].Title = "Source URI: [$($script:JamfUri)/accounts/groupid/$id]"
                                        $detail = Invoke-JamfApiCall -Endpoint "$($script:JamfUri)/groupid/$id" -apiVersion $script:JamfApiVersion -Method GET -ErrorAction Stop

                                    }
                                }

                            }default {
                                $script:statusBar.Items[4].Title = "Source URI: [$($script:JamfUri)/id/$id]"
                                $detail = Invoke-JamfApiCall -Endpoint "$($script:JamfUri)/id/$id" -apiVersion $script:JamfApiVersion -Method GET -ErrorAction Stop
                            }
                        }
                        
                        $script:DetailsTextView.Text = $detail | ConvertTo-Json -Depth 10
                    } catch {
                        Write-Log -Message "Jamf detail call failed: $($_.Exception.Message)" -Level "ERROR"
                        $script:DetailsTextView.Text = ($item | ConvertTo-Json -Depth 10)
                    }
                } else {
                    $script:DetailsTextView.Text = ($item | ConvertTo-Json -Depth 10)
                }
            }
        })
}