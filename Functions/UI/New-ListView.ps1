function New-ListView {
    param (
        [View]$Frame,
        [string[]]$Items
    )
    $listView = [ListView]::new($Items)
    $listView.X = 0
    $listView.Y = 0
    $listView.Width = [Dim]::Fill()
    $listView.Height = [Dim]::Fill()
    $Frame.Add($listView)
    return $listView
}