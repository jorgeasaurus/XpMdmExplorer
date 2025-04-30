function Show-WelcomeDialog {
    [CmdletBinding()] param()
    # ASCII art banner for XpMdm
    $ascii = @"

██╗  ██╗██████╗ ███╗   ███╗██████╗ ███╗   ███╗
╚██╗██╔╝██╔══██╗████╗ ████║██╔══██╗████╗ ████║
 ╚███╔╝ ██████╔╝██╔████╔██║██║  ██║██╔████╔██║
 ██╔██╗ ██╔═══╝ ██║╚██╔╝██║██║  ██║██║╚██╔╝██║
██╔╝ ██╗██║     ██║ ╚═╝ ██║██████╔╝██║ ╚═╝ ██║
╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝╚═════╝ ╚═╝     ╚═╝

XpMdmExplorer
A terminal user interface for Intune and Jamf Pro. 
v$($script:scriptVer)
2025 Jorgeasaurus
                                                  
"@
    [MessageBox]::Query('Welcome to XpMdm', $ascii, 0, @('OK')) | Out-Null
}