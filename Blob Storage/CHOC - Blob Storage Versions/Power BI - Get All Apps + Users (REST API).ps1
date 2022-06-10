#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/apps-get-apps-as-admin

#DESCRIPTION: Extract all apps and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    $Top = 5000 #Max number of apps that can be extracted in a single batch based on API limitations.

    #Url for relevant query to run.
    $ApiUri = "admin/apps?`$top=$Top"

    #File name for temporary staging file.
    $File = "Apps + Users Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Apps + Users Final.csv"

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

#Create object to store app and parsed user info to.
$AppsObject = @()

#Since an app may have multiple users, split users out into individual records. #For each app...
ForEach($Item in $ResultValue) {

    #Store app ID for use in apps API below.
    $appId = $Item.id

    #Execute apps API for the given app ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/apps/$appId/users" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add app info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'appId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'appName' -Value $Item.name
    $APIValue | Add-Member -MemberType NoteProperty -Name 'appLastUpdated' -Value $Item.lastUpdate
    $APIValue | Add-Member -MemberType NoteProperty -Name 'appDescription' -Value $Item.description
    $APIValue | Add-Member -MemberType NoteProperty -Name 'appPublishedBy' -Value $Item.publishedBy
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $Item.workspaceId

    #Add object to array.
    $AppsObject += $APIValue

}

#Format results in tabular format.
$AppsObject | Export-Csv $File

#End script here.

#Connect to Az account using service principal.
Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $Credentials -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup |
Get-AzStorageContainer -Name $ContainerName |
Set-AzStorageBlobContent -File $File -Blob $FileSave -Force