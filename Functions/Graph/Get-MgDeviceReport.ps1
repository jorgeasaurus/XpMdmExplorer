function Get-MgDeviceReport {
    [CmdletBinding(DefaultParameterSetName = 'Json')]
    param(

        [string] $select,
        [int]    $Top = 50,
        [int]    $Skip = 0,
        [string] $Filter = "",
        [string] $Search = "",
        [ValidateSet("Device Compliance", "Configuration Policy Summary", "Device NonCompliance", "Apps Install Summary","Mobile app install failures")]
        [string] $report
    )

    $body = [PSCustomObject]@{
        id     = ""
        top    = $Top
        skip   = $Skip
        filter = $Filter
        search = $Search
    }

    switch ($report) {
        "Device Compliance" {
            $EndpointUrl = "/deviceManagement/reports/getCachedReport"
            $body.id = "DeviceCompliance_00000000-0000-0000-0000-000000000002"
            break
        }
        "Configuration Policy Summary" {
            $EndpointUrl = "/deviceManagement/reports/getCachedReport"
            $body.id = "ConfigurationPolicyAggregateSummary_00000000-0000-0000-0000-000000000002"
            break
        }
        "Apps Install Summary" {
            $EndpointUrl = "/deviceManagement/reports/getAppsInstallSummaryReport"
            break
        }
        "Device NonCompliance" {
            $EndpointUrl = "/deviceManagement/reports/getDeviceNonComplianceReport"
            break
        }
        "Mobile app install failures" {
            $EndpointUrl = "/deviceManagement/reports/getFailedMobileAppsSummaryReport"
            break
        }
    }

    $jsonBody = $body | ConvertTo-Json -Depth 5

    try {
        # Issue the POST and capture raw HTTP response
        $respMsg = Invoke-MgGraphRequest `
            -Method POST `
            -Uri "https://graph.microsoft.com/beta$EndpointUrl" `
            -Body $jsonBody `
            -ContentType "application/json" `
            -OutputType HttpResponseMessage
    } catch {
        Throw "Report invocation failed for '$EndpointUrl': $($_.Exception.Message)"
    }

    # Pull CSV/JSON payload off the response
    $json = $respMsg.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $parsed = $json | ConvertFrom-Json

    # Map Schema + Values to PSCustomObjects
    $schema = $parsed.Schema
    $rows = $parsed.Values

    foreach ($row in $rows) {
        $props = @{}
        for ($i = 0; $i -lt $schema.Count; $i++) {
            $props[$schema[$i].Column] = $row[$i]
        }
        [PSCustomObject]$props
    }
}