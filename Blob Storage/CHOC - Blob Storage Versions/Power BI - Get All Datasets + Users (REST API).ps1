#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-datasets-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-dataset-users-as-admin

#DESCRIPTION: Extract all datasets and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    #Start parameters here.

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "T.h8Q~8uuA5i4kapZGIS4Nzd1e2UqTnnDF8_sasj"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    $ApiUri = "admin/datasets"

    #File name for temporary staging file.
    $File = "Datasets + Users Staging.csv" 

    #File name to be saved in Blob Storage.
    $FileSave = "Datasets + Users Final.csv"

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

#Create object to store dataset and parsed user info to.
$DatasetsObject = @()

#Since a dataset may have multiple users, split users out into individual records. #For each dataset...
ForEach($Item in $ResultValue) {

    #Store dataset ID for use in datasets API below.
    $datasetId = $Item.id

    #Delete ProcessError variable if exists from the previous loop execution.
    Remove-Variable ProcessError -ErrorAction SilentlyContinue

    #Execute dataset API for the given dataset ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/datasets/$datasetId/users" -Method Get -ErrorAction SilentlyContinue -ErrorVariable ProcessError

    If($ProcessError){

        Write-Output "Dataset $datasetId could not be found... skipping to next dataset."

    }

    Else{

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add dataset info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $Item.name
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetUrl' -Value $Item.webUrl
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $Item.configuredBy
    $APIValue | Add-Member -MemberType NoteProperty -Name 'isRefreshable' -Value $Item.isRefreshable
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetCreatedDate' -Value $Item.createdDate

    #Add object to array.
    $DatasetsObject += $APIValue

    #Add pause to loop to reduce risk of 429 - Too Many Requests issue.
    #API limit is 200 requests per hour, which would be 1 request every 18 seconds. Increasing to 20 seconds to be safe.
    Start-Sleep -Seconds 20

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