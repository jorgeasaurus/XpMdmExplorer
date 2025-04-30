<#
.SYNOPSIS
    Centralized logging function for the XpMdmTUI.
.DESCRIPTION
    Writes timestamped log entries to console and an optional log file,
    supporting multiple log levels.
.PARAMETER Message
    The message to log.
.PARAMETER Level
    The severity level: DEBUG, INFO, WARN, or ERROR. Default is INFO.
#>

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    # Timestamp and format
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $entry = "$timestamp [$Level] $Message"

    # Optional console output controlled by $script:VerboseLogging
    if ($script:VerboseLogging) {
        switch ($Level) {
            'ERROR' { Write-Error $entry }
            'WARN' { Write-Warning $entry }
            'DEBUG' { Write-Verbose $entry -Verbose }
            default { Write-Host $entry }
        }
    }

    # Always write to the log file
    try {
        $logDir = Split-Path -Parent $script:LogFile
        if (-not (Test-Path $logDir)) {
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        }
        Add-Content -Path $script:LogFile -Value $entry -Encoding UTF8
    } catch {
        Write-Warning "Unable to write to log file '$script:LogFile': $_"
    }
}
