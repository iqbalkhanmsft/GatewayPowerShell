#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-group-users-as-admin

#DESCRIPTION: Extract all workspaces and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "T.h8Q~8uuA5i4kapZGIS4Nzd1e2UqTnnDF8_sasj"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Uri for relevant query to run.
    #$ApiUri = '/admin/groups?$top=5000&' + '$filter=state eq' + " 'Active'"

    #Uri for active, group workspaces only.
    $ApiUri = '/admin/groups?$top=5000&' + '$filter=state eq' + " 'Active'" + ' and type eq' + " 'Workspace'"

    #File name for temporary staging file.
    $File = "Workspaces + Users Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Workspaces + Users Final.csv"

    #End parameters here.

    #Storage account info.
    $ResourceGroup = "pocs"
    $StorageAccount = "customerpocstorage"
    $ContainerName = "ch-colorado"
    $Subscription = "f29abab0-37b7-4f91-831b-d02d5cd80d7b"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Disable autosave of service principal secret.
Disable-AzContextAutosave -Scope Process

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

#Create object to store workspace and parsed user info to.
$WorkspacesObject = @()

#Since a workspace may have multiple users, split users out into individual records.
#For each workspace...
ForEach($Item in $ResultValue) {

    #Store workspace ID for use in workspace API below.
    $workspaceId = $Item.id

    #Execute workspace API for the given workspace ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/groups/$workspaceId/users" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add workspace info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $Item.isOnDedicatedCapacity
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $Item.type
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceState' -Value $Item.state
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $Item.name

    #Add object to array.
    $WorkspacesObject += $APIValue

    #Add pause to loop to reduce risk of 429 - Too Many Requests issue.
    #API limit is 200 requests per hour, which would be 1 request every 18 seconds. Increasing to 20 seconds to be safe.
    Start-Sleep -Seconds 20

}

#Format results in tabular format.
$WorkspacesObject | Export-Csv $File

#End script here.

#Connect to Az account using service principal.
Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $Credentials -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup |
Get-AzStorageContainer -Name $ContainerName |
Set-AzStorageBlobContent -File $File -Blob $FileSave -Force