function Setup-Application {
    # Initialize for welcome dialog, then reset UI for main application
    [Application]::Init()
    [Application]::QuitKey = 27
    Show-WelcomeDialog
    # Tear down welcome dialog and reinitialize for primary UI
    [Application]::Shutdown()
    [Application]::Init()
    [Application]::QuitKey = 27
    # Create main window
    $script:Window = $mainWindow = [Window]::new("XpMdmExplorer")
    $mainWindow.X = 0; $mainWindow.Y = 1
    $mainWindow.Width = [Dim]::Fill(); $mainWindow.Height = [Dim]::Fill()
}