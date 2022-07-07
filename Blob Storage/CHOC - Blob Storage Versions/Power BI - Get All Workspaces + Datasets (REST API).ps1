#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin

#DESCRIPTION: Extract all workspaces + datasets via REST API and service principal.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    #$ApiUri = "admin/groups?`$top=$Top&`$expand=datasets"

    #Url for relevant query to run.
    $ApiUri = '/admin/groups?$top=5000&' + '$expand=datasets&'+ '$filter=state eq' + " 'Active'"

    #File name for temporary staging file.
    $File = "Workspaces + Datasets Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Workspaces + Datasets Final.csv"

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

#Filter results to only those workspaces with datasets.
$Filtered = $APIValue | Where-Object {$_.datasets -ne $null}

#Create object to store workspace + parsed dataset info to.
$DatasetsObject = @()

#Since a workspace may have multiple datasets, create a custom object for each individual dataset in a workspace.
#For each workspace...
ForEach($Item in $Filtered) {

    #And for each dataset...
    ForEach($SecondItem in $Item.Datasets) {

    #Create a custom object to store values within.
    $Object = New-Object PSObject
    $Object | Add-Member -MemberType NoteProperty -Name workspaceId ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceName ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceType ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceState ''
    $Object | Add-Member -MemberType NoteProperty -Name isOnDedicatedCapacity ''

    $Object | Add-Member -MemberType NoteProperty -Name datasetId ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetName ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetConfiguredBy ''
    $Object | Add-Member -MemberType NoteProperty -Name isRefreshable ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetCreatedDate ''

    #Store values from workspace and underlying dataset.
    $Object.workspaceId = $Item.id
    $Object.workspaceName = $Item.name
    $Object.workspaceType = $Item.type
    $Object.workspaceState = $Item.state
    $Object.isOnDedicatedCapacity = $Item.isOnDedicatedCapacity

    $Object.datasetId = $SecondItem.id
    $Object.datasetName = $SecondItem.name
    $Object.datasetConfiguredBy = $SecondItem.configuredBy
    $Object.isRefreshable = $SecondItem.isRefreshable
    $Object.datasetCreatedDate = $SecondItem.createdDate
    
    #Append object data to array.
    $DatasetsObject +=$Object

    }

}

#Format results in tabular format.
$DatasetsObject | Export-Csv $File

#End script here.

#Connect to Az account using service principal.
Connect-AzAccount -ServicePrincipal -Tenant $TenantID -Credential $Credentials -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $StorageAccount -ResourceGroupName $ResourceGroup |
Get-AzStorageContainer -Name $ContainerName |
Set-AzStorageBlobContent -File $File -Blob $FileSave -Force