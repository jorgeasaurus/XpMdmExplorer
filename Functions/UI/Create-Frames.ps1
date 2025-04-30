function Create-Frames {

    $f = @{
        Title  = $null
        X      = $null
        Y      = $null
        Width  = $null
        Height = $null
    }

    $f.Title = "Intune"
    $f.X = 0
    $f.Y = 1
    $f.Width = [Dim]::Percent(10)
    $f.Height = [Dim]::Percent(36)

    $script:intuneCategoriesFrame = New-Frame @f

    $f.Title = "Jamf"
    $f.Y = [Pos]::Bottom($script:intuneCategoriesFrame)

    $script:jamfCategoriesFrame = New-Frame @f
    
    $f.Title = "Actions"
    $f.Y = [Pos]::Bottom($script:jamfCategoriesFrame)
    $f.Width = [Dim]::Percent(10)
    $f.Height = [Dim]::Percent(28)

    $script:categoriesActionsFrame = New-Frame @f
    
    $f.Title = "Overview"
    $f.X = [Pos]::Right($script:intuneCategoriesFrame)
    $f.Y = 1
    $f.Width = 30
    $f.Height = [Dim]::Percent(98)
    $script:subCategoriesFrame = New-Frame @f

    $f.Title = "Items"
    $f.X = [Pos]::Right($script:subCategoriesFrame)
    $f.Width = "Fill"
    $f.Height = [Dim]::Percent(48)
    $script:itemsFrame = New-Frame @f

    $f.Title = "Details"
    $f.Y = [Pos]::Bottom($script:itemsFrame)
    $f.Height = [Dim]::Percent(50)
    $script:detailsFrame = New-Frame @f

}