#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-datasets-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-refresh-history-in-group

#DESCRIPTION: Extract all datasets (using the Admin + Groups call) via REST API and service principal.
#Script then extracts each dataset's refresh history and appends all records to a final table.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Uri to extract all datasets across all workspaces.
    $ApiUri = "admin/groups?`$top=5000&`$expand=datasets"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - Refresh History for All Datasets.json"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store workspace + dataset info to.
$DatasetList = @()

#For each dataset in a workspace, create custom object with dataset (+ overarching workspace) info.
foreach($Item in $ResultValue)
{
    #Since a workspace may have multiple datasets, loop through dataset IDs in the workspace record and create a unique object for each.
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

#Convert array to JSON and store to file.
$RefreshHistory | ConvertTo-Json | Out-File $FileName