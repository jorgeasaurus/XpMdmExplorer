#convert a collection of objects to a System.Data.Datatable

Function ConvertTo-DataTable {
    [cmdletbinding()]
    [OutputType('System.Data.DataTable')]
    [alias('alias')]
    Param(
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        [ValidateNotNullOrEmpty()]
        [object]$InputObject
    )

    Begin {
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Starting $($MyInvocation.MyCommand)"
        Write-Verbose "[$((Get-Date).TimeOfDay) BEGIN  ] Running under PowerShell version $($PSVersionTable.PSVersion)"
        $data = [System.Collections.Generic.List[object]]::New()
        $Table = [System.Data.DataTable]::New("PSData")
    } #begin

    Process {
        $Data.Add($InputObject)
    } #process

    End {
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Building a table of $($data.count) items"
        
        # define columns
        foreach ($prop in $data[0].PSObject.Properties) {
            $val = $prop.Value
            if ($val -eq $null) {
                $t = [string]
            } else {
                $t = $val.GetType()
                if ($t.IsGenericType -and $t.GetGenericTypeDefinition() -eq ([Nullable``1])) {
                    $t = $t.GetGenericArguments()[0]
                }
                # treat complex or nested objects as strings to avoid DataTable type mismatches
                if ($t.IsInterface -or $t.IsArray -or $t.Namespace -like 'Microsoft.Graph*' -or 
                    $val -is [System.Collections.IDictionary] -or $t.FullName -eq 'System.Management.Automation.PSCustomObject') {
                    $t = [string]
                }
            }
            $col = $table.Columns.Add($prop.Name, $t)
            $col.AllowDBNull = $true
        }
        
        # add rows
        for ($i = 0; $i -lt $data.Count; $i++) {
            $row = $table.NewRow()
            foreach ($item in $data[$i].PSObject.Properties) {
                $row[$item.Name] = if ($null -eq $item.Value) { [DBNull]::Value } else { $item.Value }
            }
            [void]$table.Rows.Add($row)
        }
        #This is a trick to return the table object
        #as the output and not the rows
        , $table
        Write-Verbose "[$((Get-Date).TimeOfDay) END    ] Ending $($MyInvocation.MyCommand)"
    } #end

} #close ConvertTo-DataTable