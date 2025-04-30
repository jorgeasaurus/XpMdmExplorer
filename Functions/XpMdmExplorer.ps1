using namespace Terminal.Gui
# using namespace Terminal.Gui has been moved to the top of the script
function XpMdmExplorer {
    $ErrorActionPreference = 'Stop'

    Initialize-Logging    
    Load-Assemblies
    Initialize-UI
}
