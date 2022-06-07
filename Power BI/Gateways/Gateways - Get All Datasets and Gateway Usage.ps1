#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-datasets-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-datasources-in-group

#REMINDER: WILL NEED TO LOOP THROUGH MORE THAN 5000 WORKSPACES. CHANGE ARRAY NAMES.

#DESCRIPTION: Extract all datasets (using the Admin + Groups call) via REST API and service principal.
#The script then extracts info on all underlying data sources for each dataset - including whether they use a gateway - and appends all records to a final table.

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
$FileName = $File + "Power BI - Gateway Usage for All Datasets.json"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Execute REST API to get all workspaces and underlying Power BI datasets.
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
        $Object | Add-Member -MemberType NoteProperty -Name test ''

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

#Create object to store workspace + dataset (+ data source / gateway info) to.
$GatewayInfo = @()

#For each dataset in a workspace, create custom object with dataset + workspace (+ data source / gateway) info.
ForEach($ThirdItem in $Refreshables)
    {

    #Test values.
    #$workspaceId = "0be252fd-f744-4d90-b1ce-b06c0a2a5f6b"
    #$datasetId = "c651d397-e2cb-426e-8847-c992e19c858e"

    #Store dataset values for use in data source / gateway API below.
    $workspaceId = $ThirdItem.workspaceId
    $datasetId = $ThirdItem.datasetId

    #Execute data source / gateway API API for the given dataset in the loop.
    $APIResult = Invoke-PowerBIRestMethod -Url "groups/$workspaceId/datasets/$datasetId/datasources" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add additional info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $workspaceId
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $datasetId
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $ThirdItem.workspaceName
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $ThirdItem.workspaceType
    $APIValue | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $ThirdItem.isOnDedicatedCapacity
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $ThirdItem.datasetName
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $ThirdItem.datasetConfiguredBy
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetCreatedDate' -Value $ThirdItem.datasetCreatedDate

    #Add object to array.
    $GatewayInfo += $APIValue | Where-Object {$_.gatewayId -ne $null}

}

#Convert array to JSON and store to file.
$GatewayInfo | ConvertTo-Json | Out-File $FileName

#Create object to store workspace + dataset (+ data source / gateway info) to.
$GatewayName = @()

#For each dataset in a workspace, create custom object with dataset + workspace (+ data source / gateway) info.
ForEach($FourthItem in $GatewayInfo)
    {

    #Test.
    $gatewayId = "ad48aedb-7688-4f35-bf62-c70cf627a62e"

    #Store dataset values for use in data source / gateway API below.
    $gatewayId = $ThirdItem.gatewayId

    #Execute data source / gateway API API for the given dataset in the loop.
    $gatewayResult = Invoke-PowerBIRestMethod -Url "gateways/$gatewayId" -Method Get

    #Store API response's value component only.
    $gatewayValue = ($gatewayResult | ConvertFrom-Json).'value'

    #Add additional info to API response.
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $workspaceId
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $datasetId
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $ThirdItem.workspaceName
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $ThirdItem.workspaceType
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $ThirdItem.isOnDedicatedCapacity
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $ThirdItem.datasetName
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $ThirdItem.datasetConfiguredBy
    $gatewayValue | Add-Member -MemberType NoteProperty -Name 'datasetCreatedDate' -Value $ThirdItem.datasetCreatedDate

    #Add object to array.
    $GatewayName += $APIValue #| Where-Object {$_.gatewayId -ne $null}

}

#Convert array to JSON and store to file.
$GatewayName #| ConvertTo-Json | Out-File $FileName