#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin

#DESCRIPTION: Extract all workspaces + dashboards via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "dih8Q~J.MvNuTB5PLUwuYcJOFzQuLmhMKOemZdkE"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    $Top = 5000 #Number of workspaces to return; max = 5000.

    #Url for relevant query to run.
    $ApiUri = "admin/groups?`$top=$Top&`$expand=reports"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspaces + Reports (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get

#Store API response's value component only.
$APIValue = ($Result | ConvertFrom-Json).'value'

#Filter results to only those workspaces with dashboards.
$Filtered = $APIValue | Where-Object {$_.reports -ne $null}

#Create object to store workspace + dataset (+ data source / gateway info) to.
$ReportsObject = @()

#For each dataset in a workspace, create a custom object with dataset + workspace (+ data source / gateway) info.
#For each dataset...
ForEach($Item in $Filtered) {

    #And for each dataset...
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

    #Store values from workspace and underlying dataset.
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
    
    #Only return refreshable datasets.
    $ReportsObject +=$Object

    }

}

#Format results in tabular format.
$ReportsObject | Export-Csv $FileName