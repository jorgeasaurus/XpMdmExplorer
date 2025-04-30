function New-Frame {
    param (
        [string]$Title,
        $X,
        $Y,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Width,
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        $Height
    )
    $frame = [FrameView]::new($Title)
    $frame.X = $X
    $frame.Y = $Y
    $frame.Width = if ($Width -eq "Fill") { [Dim]::Fill() } else { $Width }
    $frame.Height = if ($Height -eq "Fill") { [Dim]::Fill() } else { $Height }
    return $frame
}