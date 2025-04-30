<#
.SYNOPSIS
    Maps UI categories and subcategories to their Graph API URIs.
.DESCRIPTION
    Provides a lookup table for the TUI to resolve which URI to call for a given category and subcategory.
#>
# Global lookup of category -> subcategory -> Graph URI
$Global:intuneCommandMappings = [ordered]@{
    'Home'    = [ordered]@{
        'Device compliance summary'       = '/beta/deviceManagement/deviceCompliancePolicyDeviceStateSummary'
        'APNs certificates'               = '/beta/deviceManagement/applePushNotificationCertificate'
        'Managed device overview entries' = '/beta/deviceManagement/managedDeviceOverview'
    }
    'Devices' = [ordered]@{
        'All Devices'          = '/beta/deviceManagement/managedDevices'
        '-----------'          = '/beta/deviceManagement/managedDevices'
        'Windows Devices'      = '/beta/deviceManagement/managedDevices?$filter=operatingSystem eq ''Windows'''
        'macOS Devices'        = '/beta/deviceManagement/managedDevices?$filter=operatingSystem eq ''macOS'''
        'iOS/iPadOS Devices'   = '/beta/deviceManagement/managedDevices?$filter=operatingSystem eq ''iOS'' or operatingSystem eq ''iPadOS'''
        'Android Devices'      = '/beta/deviceManagement/managedDevices?$filter=operatingSystem eq ''Android'''
        'Linux Devices'        = '/beta/deviceManagement/managedDevices?$filter=deviceType eq ''Linux'''
        '---------------'      = '/beta/deviceManagement/managedDevices'
        'Platform Scripts'     = '/beta/deviceManagement/deviceManagementScripts'
        'Remediation Scripts'  = '/beta/deviceManagement/deviceHealthScripts'
        'Device Configuration' = '/beta/deviceManagement/deviceConfigurations'
        'Device Compliance'    = '/beta/deviceManagement/deviceCompliancePolicies'
        'Settings Catalog'     = '/beta/deviceManagement/configurationPolicies'
        'Device Categories'    = '/beta/deviceManagement/deviceCategories'
        'Device Filters'       = '/beta/deviceManagement/assignmentFilters'
        '--------------'       = '/beta/deviceManagement/assignmentFilters'
        'Conditional Access'   = '/beta/identity/conditionalAccess/policies'

    }
    'Apps'    = [ordered]@{
        'All Apps'                  = '/beta/deviceAppManagement/mobileApps'
        '--------'                  = '/beta/deviceAppManagement/mobileApps'
        'Windows'                   = '/beta/deviceAppManagement/mobileApps'
        'iOS/iPadOS'                = '/beta/deviceAppManagement/mobileApps'
        'macOS'                     = '/beta/deviceAppManagement/mobileApps'
        'Android'                   = '/beta/deviceAppManagement/mobileApps'
        '-------'                   = '/beta/deviceAppManagement/mobileApps'
        'App Configuration'         = '/beta/deviceAppManagement/mobileAppConfigurations'
        'Managed App Configuration' = '/beta/deviceAppManagement/targetedManagedAppConfigurations'
        'App Protection Policies'   = '/beta//deviceAppManagement/managedAppPolicies'
        'App Categories'            = '/beta/deviceAppManagement/mobileAppCategories'
        'Discovered Apps'           = '/beta/deviceManagement/detectedApps'
    }
    'Groups'  = [ordered]@{
        'All Groups'     = '/beta/groups'
        'Deleted Groups' = '/beta/directory/deletedItems/microsoft.graph.group'
    }
    'Users'   = [ordered]@{
        'All Users'    = '/beta/users'
        'Audit Logs'   = '/beta/deviceManagement/auditEvents'
        'Sign-in Logs' = '/beta/auditLogs/signIns'
    }
    'Reports' = [ordered]@{
        'Device Compliance'            = '/beta/deviceManagement/reports/getCachedReport'
        'Configuration Policy Summary' = '/beta/deviceManagement/reports/getCachedReport'
        'Mobile app install failures'  = '/beta/deviceManagement/reports/getFailedMobileAppsSummaryReport'
        'Device NonCompliance'         = '/beta/deviceManagement/reports/getDeviceNonComplianceReport'
        'Apps Install Summary'         = '/beta/deviceManagement/reports/getAppsInstallSummaryReport'  
    }
}

$Global:jamfCommandMappings = [ordered]@{
    'Computers'      = [ordered]@{
        'Inventory'                     = '/JSSResource/computers';
        'Policies'                      = '/JSSResource/policies';
        'Configuration Profiles'        = '/JSSResource/osxconfigurationprofiles';
        'Computer Groups'               = '/JSSResource/computergroups';
        'Scripts'                       = '/JSSResource/scripts';
        'Computer Extension Attributes' = '/JSSResource/computerextensionattributes';
        'Packages'                      = '/JSSResource/packages';
        'Restricted Software'           = '/JSSResource/restrictedsoftware';
        'Mac Applications'              = '/JSSResource/macapplications';
        'Computer Prestages'            = '/api/v2/computer-prestages';
    }
    'Mobile Devices' = [ordered]@{
        'Mobile Devices'                       = '/JSSResource/mobiledevices';
        'Mobile Device Apps'                   = '/JSSResource/mobiledeviceapplications';
        'Mobile Device Configuration Profiles' = '/JSSResource/mobiledeviceconfigurationprofiles';
        'Mobile Device Extension Attributes'   = '/JSSResource/mobiledeviceextensionattributes';
        'Mobile Device Enrollment Profiles'    = '/api/v2/mobile-device-prestages';
    }   
    'Jamf Users'     = [ordered]@{
        'Users'  = '/JSSResource/users';
        'Groups' = '/JSSResource/usergroups';
    }
    'Accounts'       = [ordered]@{
        'Users'  = '/JSSResource/accounts';
        'Groups' = '/JSSResource/accounts';
    }
    'Settings'       = [ordered]@{
        'Buildings'   = '/JSSResource/buildings';
        'Departments' = '/JSSResource/departments';
        'Categories'  = '/JSSResource/categories';
    }
}

