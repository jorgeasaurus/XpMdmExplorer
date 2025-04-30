# XPMDMExplorer Module Entry
# Imports all functions from the Functions directory.
# XPMDMExplorer.psm1


$script:ScriptVer = '0.1.0'

# Import Functions
Get-ChildItem -Path "$PSScriptRoot/Functions" -Recurse -Include *.ps1 | ForEach-Object {
    . $_.FullName
}

# Initialize logging (sets $script:LogFile)
Initialize-Logging

# Log module load
Write-Log -Message "XPMDMExplorer module loaded successfully." -Level "INFO"