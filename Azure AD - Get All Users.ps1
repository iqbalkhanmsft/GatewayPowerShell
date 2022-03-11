function Get-GraphApiResult {

    param (
        [parameter(Mandatory = $true)]
        $ClientID,

        [parameter(Mandatory = $true)]
        $ClientSecret,

        [parameter(Mandatory = $true)]
        $TenantName,

        [parameter(Mandatory = $true)]
        $Uri
    )

    # Graph API URLs.
    $LoginUrl = "https://login.microsoft.com"
    $RresourceUrl = "https://graph.microsoft.com"

    # Compose REST request.
    $Body = @{ grant_type = "client_credentials"; resource = $RresourceUrl; client_id = $ClientID; client_secret = $ClientSecret }     
    
    $OAuth = Invoke-RestMethod -Method Post -Uri $LoginUrl/$TenantName/oauth2/token?api-version=1.0 -Body $Body

    # Check if authentication was successful.
    if ($OAuth.access_token) {
        # Format headers.
        $HeaderParams = @{
            'Content-Type'  = "application\json"
            'Authorization' = "$($OAuth.token_type) $($OAuth.access_token)"
        }

        # Create an empty array to store the result.
        $QueryResults = @()
        
        # Invoke REST method and fetch data until there are no pages left.
        do {
            $Results = Invoke-RestMethod -Headers $HeaderParams -Uri $Uri -UseBasicParsing -Method "GET" -ContentType "application/json"
            if ($Results.value) {
                $QueryResults += $Results.value
            }
            else {
                $QueryResults += $Results
            }
            $uri = $Results.'@odata.nextlink'
        } until (!($uri))

        # Return the result.
        $QueryResults
    }
    else {
        Write-Error "No Access Token"
    }
}

Get-GraphApiResult -ClientID "9d241b3d-fb86-41a0-a00d-9bee7b9fd855" -ClientSecret "zes7Q~2RbposuEY0c7M.M5RNogp6Z6k.w.4rg" -TenantName "powerbidawgs.com" -Uri "https://graph.microsoft.com/v1.0/users/"