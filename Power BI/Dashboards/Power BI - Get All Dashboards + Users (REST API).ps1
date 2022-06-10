#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/apps-get-apps-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/dashboards-get-dashboard-users-as-admin

#DESCRIPTION: Extract all apps and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "dih8Q~J.MvNuTB5PLUwuYcJOFzQuLmhMKOemZdkE"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run.
    $ApiUri = "admin/dashboards"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Dashboards + Users (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store app and parsed user info to.
$DashboardsObject = @()

#Since an app may have multiple users, split users out into individual records. #For each app...
ForEach($Item in $ResultValue) {

    #Store app ID for use in apps API below.
    $dashboardId = $Item.id

    #Execute apps API for the given app ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/dashboards/$dashboardId/users" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add app info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'dashboardId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'dashboardName' -Value $Item.displayName

    #Add object to array.
    $DashboardsObject += $APIValue

}

#Format results in tabular format.
$DashboardsObject | Export-Csv $FileName