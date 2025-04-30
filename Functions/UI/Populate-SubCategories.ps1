<#
.SYNOPSIS
    Populates subcategory list based on the selected category.

.DESCRIPTION
    Uses a switch statement to select a list of subcategories for each category,
    updates the SubCategoriesListView source, and clears downstream panes.
#>
function Populate-SubCategories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Category
    )

    Write-Log -Message "Populating subcategories for category: $Category" -Level "INFO"
    
    # 1) Force a layout pass so Bounds gets populated
    $script:subCategoriesFrame.LayoutSubviews()

    # 2) Read the actual width
    $script:frameWidth = $script:subCategoriesFrame.Bounds.Width

    # 3) Compute a non-negative dash length
    $script:dashCount = [Math]::Max(0, $frameWidth - 1)

    # 4) Generate your separator
    $script:separator = ''.PadRight($dashCount, '-')


    # Dynamically retrieve subcategories based on CommandMappings (Intune or Jamf)
    if ($Global:intuneCommandMappings.Contains($Category)) {
        $subs = @($Global:intuneCommandMappings[$Category].Keys)
    } elseif ($Global:jamfCommandMappings.Contains($Category)) {
        $subs = @($Global:jamfCommandMappings[$Category].Keys)
    } else {
        $subs = @()
    }

    # Update the subcategories list view
    $script:SubCategoriesListView.SetSource($subs)

    # Clear stored items when category changes
    $global:CurrentItems = @()
    $global:RawItems = @()
    $global:FilteredItems = @()
    # Clear the items table if present
    if ($script:ItemsTableView) {
        $script:ItemsTableView.Table = $null
    } elseif ($script:ItemsListView) {
        # Fallback for list view
        $script:ItemsListView.SetSource(@())
    }
    # Clear details pane
    $script:DetailsTextView.Text = ''
}