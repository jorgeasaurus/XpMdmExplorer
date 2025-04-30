@{
    # Script module file associated with this manifest
    RootModule            = 'XpMdmExplorer.psm1'

    # Version number of this module
    ModuleVersion         = '0.1.0'

    # ID used to uniquely identify this module
    GUID                  = '8A437B96-7D00-49F4-A773-94D94E1E2A9F'

    # Author of this module
    Author                = 'jorgeasaurus'

    # Company or vendor of this module
    CompanyName           = ''

    # Copyright statement for this module
    Copyright             = '(c) 2025 jorgeasaurus. All rights reserved.'

    # Description of the functionality provided by this module
    Description           = 'Terminal-based cross-platform TUI for exploring and managing devices, apps, and users in Microsoft Intune and Jamf Pro.'

    # Minimum PowerShell version required by this module
    PowerShellVersion     = '7.0'

    # Processor architecture for which this module is intended
    ProcessorArchitecture = 'MSIL'

    # Edition of PowerShell for which this module is intended
    CompatiblePSEditions   = @('Core')

    # List of modules that must be imported prior to this module
    RequiredModules       = @('Microsoft.Graph')

    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies    = @()

    # Modules to import as nested modules
    NestedModules         = @()

    # Script files to process in the caller's environment prior to module import
    ScriptsToProcess      = @()

    # Type and format files to process
    TypesToProcess        = @()
    FormatsToProcess      = @()

    # List of functions, cmdlets, aliases, and variables to export from this module
    FunctionsToExport     = @('*')
    CmdletsToExport       = @()
    AliasesToExport       = @()
    VariablesToExport     = @()

    # Private data for PowerShell Gallery and tooling
    PrivateData           = @{
        PSData = @{
            Tags                   = @('TUI','Intune','Jamf','MDM','Terminal')
            LicenseUri             = 'https://raw.githubusercontent.com/jorgeasaurus/XpMdmExplorer/main/LICENSE'
            ProjectUri             = 'https://github.com/jorgeasaurus/XpMdmExplorer'
            IconUri                = 'Welcome.png'
            ReleaseNotes           = 'Initial release'
        }
    }
}