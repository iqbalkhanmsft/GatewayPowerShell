#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-datasets-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-dataset-users-as-admin

#DESCRIPTION: Extract all datasets and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "T.h8Q~8uuA5i4kapZGIS4Nzd1e2UqTnnDF8_sasj"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run.
    $ApiUri = "admin/datasets"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Datasets + Users (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

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

    #Execute dataset API for the given dataset ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/datasets/$datasetId/users" -Method Get

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

#Format results in tabular format.
$DatasetsObject | Export-Csv $FileName