#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/dashboards-get-dashboards-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/dashboards-get-dashboard-users-as-admin

#DESCRIPTION: Extract all dashboards and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    $ApiUri = "admin/dashboards"

    #File name for temporary staging file.
    $File = "Dashboards + Users Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Dashboards + Users Final.csv"

    #End parameters here.

    #Storage account info.
    $ResourceGroup = "pocs"
    $StorageAccount = "customerpocstorage"
    $ContainerName = "ch-colorado"
    $Subscription = "f29abab0-37b7-4f91-831b-d02d5cd80d7b"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Remove all modules from session.
Get-Module | Remove-Module -Force

#Import Az accounts module.
Import-Module Az.Accounts 

#Import Az storage module.
Import-Module Az.Storage

#Create credentials object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credentials = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credentials -Tenant $TenantID

#Start script here.

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store dashboard and parsed user info to.
$DashboardsObject = @()

#Since a dashboard may have multiple users, split users out into individual records. #For each dashboard...
ForEach($Item in $ResultValue) {

    #Store dashboard ID for use in dashboard API below.
    $dashboardId = $Item.id

    #Execute dashboard API for the given dashboard ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/dashboards/$dashboardId/users" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add dashboard info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'dashboardId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'dashboardName' -Value $Item.displayName

    #Add object to array.
    $DashboardsObject += $APIValue

}

#Format results in tabular format.
$DashboardsObject | Export-Csv $File

#End script here.

#Connect to Az account using service principal.
Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $Credentials -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup |
Get-AzStorageContainer -Name $ContainerName |
Set-AzStorageBlobContent -File $File -Blob $FileSave -Force