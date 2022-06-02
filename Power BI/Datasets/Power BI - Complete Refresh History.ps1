#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-datasets-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-refresh-history-in-group

#DESCRIPTION: Extract all datasets via REST API and service principal.
#Then extracts dataset refresh history for each dataset and appends to a final table.

#Notes: Clean up any unneeded code. Annotate. Add back in refresh status column. Check above annotations.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Uri to extract all datasets.
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

#Store API response values only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store parsed workspace data to.
$DatasetList = @()

#For each workspace record, create custom object with underlying dataset info.

foreach($Item in $ResultValue)

{

    foreach($SecondItem in $Item.Datasets)
    
    {

        #Create custom object.
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

$Refreshables = $DatasetList | Where-Object {$_.isRefreshable -eq 'True'}

$RefreshHistory = @()

ForEach($ThirdItem in $Refreshables)

    {

    $workspaceId = $ThirdItem.workspaceId
    $datasetId = $ThirdItem.datasetId
    $workspaceName = $ThirdItem.workspaceName
    $workspaceType = $ThirdItem.workspaceType
    $isOnDedicatedCapacity = $ThirdItem.isOnDedicatedCapacity
    $datasetName = $ThirdItem.datasetName
    $datasetConfiguredBy = $ThirdItem.datasetConfiguredBy
    $datasetCreatedDate = $ThirdItem.datasetCreatedDate
    $isRefreshable = $ThirdItem.isRefreshable

    $RefreshResult = Invoke-PowerBIRestMethod -Url "groups/$workspaceId/datasets/$datasetId/refreshes" -Method Get

    $RefreshValue = ($RefreshResult | ConvertFrom-Json).'value'

    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $workspaceId
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $datasetId
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $workspaceName
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $workspaceType
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $isOnDedicatedCapacity
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $datasetName
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $datasetConfiguredBy
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'datasetCreatedDate' -Value $datasetCreatedDate
    $RefreshValue | Add-Member -MemberType NoteProperty -Name 'isRefreshable' -Value $isRefreshable

    $RefreshHistory += $RefreshValue | Where-Object {$_.requestId -ne $null}

}

$RefreshHistory | ConvertTo-Json | Out-File $FileName