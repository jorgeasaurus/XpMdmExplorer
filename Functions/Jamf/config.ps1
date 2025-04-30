[hashtable]$script:Config = @{
    BaseUrl    = "https://tenant.jamfcloud.com" # URL of your Jamf Pro server
    Username   = "" # Leave empty if using API credentials
    Password   = "" # Leave empty if using API credentials
    #API Roles Implementation is not supported in this version 
    #clientId     = "00000000-0000-0000-0000-000000000000" # Fill if using API credentials
    #clientSecret = "your-client-secret-here" # Fill if using API credentials
    ApiVersion = "classic" # Use 'v1','v2' or 'classic'
    Token      = $null
}