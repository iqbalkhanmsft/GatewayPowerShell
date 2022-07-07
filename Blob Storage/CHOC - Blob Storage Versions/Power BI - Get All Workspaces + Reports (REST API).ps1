#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin

#DESCRIPTION: Extract all workspaces + reports via REST API and service principal.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "T.h8Q~8uuA5i4kapZGIS4Nzd1e2UqTnnDF8_sasj"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    #$ApiUri = '/admin/groups?$top=5000&' + '$skip=' + $Skip + '&$filter=state eq' + " 'Active'"

    #Url for relevant query to run.
    $ApiUri = '/admin/groups?$top=5000&' + '$expand=reports&'+ '$filter=state eq' + " 'Active'"

    #Url for relevant query to run.
    #$ApiUri = "admin/groups?`$top=$Top&`$expand=reports"

    #File name for temporary staging file.
    $File = "Workspaces + Reports Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Workspaces + Reports Final.csv"

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
$APIValue = ($Result | ConvertFrom-Json).'value'

#Filter results to only those workspaces with reports.
$Filtered = $APIValue | Where-Object {$_.reports -ne $null}

#Create object to store workspace + reports to.
$ReportsObject = @()

#Since a workspace may have multiple reports, create a custom object for each individual report in a workspace.
#For each workspace...
ForEach($Item in $Filtered) {

    #And for each report...
    ForEach($SecondItem in $Item.Reports) {

    #Create a custom object to store values within.
    $Object = New-Object PSObject
    $Object | Add-Member -MemberType NoteProperty -Name workspaceId ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceName ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceType ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceState ''
    $Object | Add-Member -MemberType NoteProperty -Name isOnDedicatedCapacity ''

    $Object | Add-Member -MemberType NoteProperty -Name reportId ''
    $Object | Add-Member -MemberType NoteProperty -Name reportName ''
    $Object | Add-Member -MemberType NoteProperty -Name reportType ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetId ''
    $Object | Add-Member -MemberType NoteProperty -Name reportCreatedDate ''
    $Object | Add-Member -MemberType NoteProperty -Name reportModifiedDate ''

    #Store values from workspace and underlying report.
    $Object.workspaceId = $Item.id
    $Object.workspaceName = $Item.name
    $Object.workspaceType = $Item.type
    $Object.workspaceState = $Item.state
    $Object.isOnDedicatedCapacity = $Item.isOnDedicatedCapacity

    $Object.reportId = $SecondItem.id
    $Object.reportName = $SecondItem.name
    $Object.reportType = $SecondItem.reportType
    $Object.datasetId = $SecondItem.datasetId
    $Object.reportCreatedDate = $SecondItem.createdDateTime
    $Object.reportModifiedDate = $SecondItem.modifiedDateTime
    
    #Append object to array.
    $ReportsObject +=$Object

    }

}

#Format results in tabular format.
$ReportsObject | Export-Csv $File

#End script here.

#Connect to Az account using service principal.
Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $Credentials -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup |
Get-AzStorageContainer -Name $ContainerName |
Set-AzStorageBlobContent -File $File -Blob $FileSave -Force