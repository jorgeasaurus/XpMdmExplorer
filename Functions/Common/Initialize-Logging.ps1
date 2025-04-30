function Initialize-Logging {
    # compute repo root (two levels up from this file)
    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $logDir = Join-Path $repoRoot "Logs"

    # ensure Logs folder exists
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # set the log‐file in the top‑level Logs folder
    $script:LogFile = Join-Path $logDir "XpMdmExplorer.log"

    # clear existing log if present
    if (Test-Path $script:LogFile) {
        Clear-Content -Path $script:LogFile
    }
}
