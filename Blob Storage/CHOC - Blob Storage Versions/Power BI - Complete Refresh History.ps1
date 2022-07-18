#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-refresh-history-in-group

#DESCRIPTION: Extract all datasets (using the Admin + Groups call) via REST API and service principal.
#Script then extracts each dataset's refresh history and appends all records to a final table.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "T.h8Q~8uuA5i4kapZGIS4Nzd1e2UqTnnDF8_sasj"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Uri to extract all datasets across all active workspaces.
    #$ApiUri = '/admin/groups?$top=5000&' + '$expand=datasets&'+ '$filter=state eq' + " 'Active'"

    #Uri to extract all datasets across all active, group workspaces.
    $ApiUri = '/admin/groups?$top=5000&' + '$expand=datasets&'+ '$filter=state eq' + " 'Active'" + ' and type eq' + " 'Workspace'"

    #File name for temporary staging file.
    $File = "Refresh History Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Refresh History Final.csv"

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
$Result = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store workspace + dataset info to.
$DatasetList = @()

#For each dataset in a workspace, create custom object with dataset (+ overarching workspace) info.
foreach($Item in $ResultValue)
{
    #Since a workspace may have multiple datasets, loop through dataset IDs in the workspace and create a unique object for each.
    foreach($SecondItem in $Item.Datasets)
    {

        #Create custom object to store values within.
        $Object = New-Object PSObject
        $Object | Add-Member -MemberType NoteProperty -Name workspaceId ''
        $Object | Add-Member -MemberType NoteProperty -Name workspaceName ''
        $Object | Add-Member -MemberType NoteProperty -Name workspaceType ''
        $Object | Add-Member -MemberType NoteProperty -Name isOnDedicatedCapacity ''
        $Object | Add-Member -MemberType NoteProperty -Name datasetId ''
        $Object | Add-Member -MemberType NoteProperty -Name datasetName ''
        $Object | Add-Member -MemberType NoteProperty -Name datasetConfiguredBy ''
        $Object | Add-Member -MemberType NoteProperty -Name datasetCreatedDate ''
        $Object | Add-Member -MemberType NoteProperty -Name isRefreshable ''

        #Store values in object.
        $Object.workspaceId = $Item.id
        $Object.workspaceName = $Item.name
        $Object.workspaceType = $Item.type
        $Object.isOnDedicatedCapacity = $Item.isOnDedicatedCapacity
        $Object.datasetId = $SecondItem.id
        $Object.datasetName = $SecondItem.name
        $Object.datasetConfiguredBy = $SecondItem.configuredBy
        $Object.datasetCreatedDate = $SecondItem.createdDate
        $Object.isRefreshable = $SecondItem.isRefreshable

        #Append object to array.
        $DatasetList += $Object

    }

}

#Filter datasets to only those that are refreshable.
$Refreshables = $DatasetList | Where-Object {$_.isRefreshable -eq 'True'}

#Create object to store workspace + dataset (+ refresh history) to.
$RefreshHistory = @()

#For each dataset in a workspace, create custom object with dataset + workspace (+ refresh history) info.
ForEach($ThirdItem in $Refreshables)
    {

    #Store dataset values for use in refresh history API below.
    $workspaceId = $ThirdItem.workspaceId
    $datasetId = $ThirdItem.datasetId

    #Execute refresh history API for the given dataset in the loop.
    $RefreshResult = Invoke-PowerBIRestMethod -Url "groups/$workspaceId/datasets/$datasetId/refreshes" -Method Get

    #Store API response's value component only.
    $RefreshValue = ($RefreshResult | ConvertFrom-Json).'value'

    #Remove null records.
    $NullsRemoved = $RefreshValue | Where-Object {$_.requestId -ne $null}

    #Add additional info to API response.
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $workspaceId
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $datasetId
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $ThirdItem.workspaceName
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $ThirdItem.workspaceType
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $ThirdItem.isOnDedicatedCapacity
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $ThirdItem.datasetName
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $ThirdItem.datasetConfiguredBy
    $NullsRemoved | Add-Member -MemberType NoteProperty -Name 'datasetCreatedDate' -Value $ThirdItem.datasetCreatedDate

    #Add object to array. Remove other id value for refresh.
    $RefreshHistory += $NullsRemoved | Select-Object -ExcludeProperty id

}

#Convert array to CSV and store to file.
$RefreshHistory | Export-Csv $File

#End script here.

#Connect to Az account using service principal.
Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $Credentials -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup |
Get-AzStorageContainer -Name $ContainerName |
Set-AzStorageBlobContent -File $File -Blob $FileSave -Force