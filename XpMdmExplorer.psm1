# XPMDMToolkit Module Entry
# Imports all functions from the Functions directory.
# XPMDMToolkit.psm1

# Import Functions
# Import all helper functions
$script:ScriptVer = '0.1.0'

Get-ChildItem -Path "$PSScriptRoot/Functions" -Recurse -Include *.ps1 | ForEach-Object {
    . $_.FullName
}

# Initialize logging (sets $script:LogFile)
Initialize-Logging

# Log module load
Write-Log -Message "XPMDMToolkit module loaded successfully." -Level "INFO"