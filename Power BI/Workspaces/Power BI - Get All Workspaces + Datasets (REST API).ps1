#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin

#DESCRIPTION: Extract all workspaces + datasets via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "dih8Q~J.MvNuTB5PLUwuYcJOFzQuLmhMKOemZdkE"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    $Top = 5000 #Number of workspaces to return; max = 5000.

    #Url for relevant query to run.
    $ApiUri = "admin/groups?`$top=$Top&`$expand=datasets"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspaces + Datasets (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

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
$DatasetsObject | Export-Csv $FileName