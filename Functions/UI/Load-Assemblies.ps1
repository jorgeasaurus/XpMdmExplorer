function Load-Assemblies {
    # Determine module root two levels up from this script's directory
    $moduleRoot = Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '..\..') | Select-Object -ExpandProperty Path
    $assemblyDir = Join-Path -Path $moduleRoot -ChildPath 'Resources\Assemblies'
    if (-not (Test-Path -Path $assemblyDir)) {
        Throw "Assembly directory not found: $assemblyDir"
    }
    # Load all DLLs in the Resources/Assemblies directory
    $dlls = Get-ChildItem -Path $assemblyDir -Filter '*.dll' | Select-Object -ExpandProperty FullName
    foreach ($dll in $dlls) {
        try {
            Add-Type -Path $dll -ErrorAction Stop
        } catch [System.IO.FileLoadException], [System.IO.FileNotFoundException] {
            # Assembly already loaded or not found – ignore error
        } catch {
            Throw
        }
    }
}