#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspace?view=powerbi-ps
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/datasets-get-datasources-as-admin

#DESCRIPTION: Extracts all workspaces and underlying datasets via PowerShell - due to no throttling on the PS commandlet for workspaces.
#Then utilizes the "Datasources as Admin" API to get each workspace dataset's underlying data source(s) - specifically those utilizing a gateway.

#NOTE: The "Datasources as Admin" API is throttled - each request takes 0.5 seconds to process.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "T.h8Q~8uuA5i4kapZGIS4Nzd1e2UqTnnDF8_sasj"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

     ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Gateway Data Sources.json"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID #-Environment USGov

#Connect to Power BI with credentials of a Power BI admin.
#Connect-PowerBIServiceAccount -Environment USGov

#Get all workspaces and underlying datasets in the organization.
$Workspaces = Get-PowerBIWorkspace -All -Scope Organization -Include Datasets

#Create object to store workspace and parsed dataset info to.
$WorkspacesObject = @()

#Since a workspace may have multiple datasets, split these out into individual records. #For each workspace...

ForEach($Item in $Workspaces) {

    #And for each dataset...
    ForEach($SecondItem in $Item.Datasets) {

    #Create a custom object to store values within.
    $Object = New-Object PSObject
    $Object | Add-Member -MemberType NoteProperty -Name workspaceId ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceName ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceType ''
    $Object | Add-Member -MemberType NoteProperty -Name workspaceState ''
    $Object | Add-Member -MemberType NoteProperty -Name isOnDedicatedCapacity ''
    $Object | Add-Member -MemberType NoteProperty -Name capacityId ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetId ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetName ''
    $Object | Add-Member -MemberType NoteProperty -Name datasetConfiguredBy ''
    $Object | Add-Member -MemberType NoteProperty -Name isRefreshable ''
    $Object | Add-Member -MemberType NoteProperty -Name isOnPremGatewayRequired ''

    #Store values from workspace and underlying dataset.
    $Object.workspaceId = $Item.id
    $Object.workspaceName = $Item.name
    $Object.workspaceType = $Item.type
    $Object.workspaceState = $Item.state
    $Object.isOnDedicatedCapacity = $Item.isOnDedicatedCapacity
    $Object.capacityId = $Item.capacityId
    $Object.datasetId = $SecondItem.id
    $Object.datasetName = $SecondItem.name
    $Object.datasetConfiguredBy = $SecondItem.configuredBy
    $Object.isRefreshable = $SecondItem.isRefreshable
    $Object.isOnPremGatewayRequired = $SecondItem.isOnPremGatewayRequired
    
    #Only return refreshable datasets.
    $WorkspacesObject +=$Object | Where-Object {$_.isRefreshable -eq "True"}

    }

}

#Create object to store workspace + dataset (+ data source / gateway info) to.
$GatewayObject = @()

#Create object to store inaccessible datasets for later review.
$ErrorOutput = @()

#Setup error file name for saving.
$ErrorFileName = $File + "Power BI - All Gateway Data Sources (Error Output).json"

#For each dataset in a workspace, create a custom object with dataset + workspace (+ data source / gateway) info.
#For each dataset...
ForEach($ThirdItem in $WorkspacesObject)
    
    {

    #Store dataset ID for use in data source / gateway API below.
    $datasetId = $ThirdItem.datasetId

    #Execute data source / gateway API for the given dataset in the loop.
    #API returns each underlying data source as an individual record so no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/datasets/$datasetId/datasources" -Method Get -ErrorVariable ProcessError

    #Catch + try for inaccessible datasets.
    If($ProcessError){

        #Warning if dataset cannot be accessed...
        Write-Warning "Dataset $DatasetId could not be found... Moving to next dataset."

        #Create PS object to store error messages to.
        $ErrorRecord = New-Object psobject

        #Add useful dataset info to object.
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $datasetId
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $ThirdItem.workspaceId
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $ThirdItem.workspaceName
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'workspaceState' -Value $ThirdItem.workspaceState
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $ThirdItem.workspaceType
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $ThirdItem.isOnDedicatedCapacity
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $ThirdItem.datasetName
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $ThirdItem.datasetConfiguredBy
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'isRefreshable' -Value $ThirdItem.isRefreshable
        $ErrorRecord | Add-Member -MemberType NoteProperty -Name 'errorMessage' -Value $ProcessError

        #Add record to array.
        $ErrorOutput += $ErrorRecord 

    }

    Else{

        #Store API response's value component only.
        $APIValue = ($APIResult | ConvertFrom-Json).'value'

        #Add workspace + dataset info to API response.
        $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $ThirdItem.workspaceId
        $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $ThirdItem.workspaceName
        $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $ThirdItem.workspaceType
        $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceState' -Value $ThirdItem.workspaceState
        $APIValue | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $ThirdItem.isOnDedicatedCapacity
        $APIValue | Add-Member -MemberType NoteProperty -Name 'capacityId' -Value $ThirdItem.capacityId
        $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $ThirdItem.datasetId
        $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetName' -Value $ThirdItem.datasetName
        $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetConfiguredBy' -Value $ThirdItem.datasetConfiguredBy
        $APIValue | Add-Member -MemberType NoteProperty -Name 'isRefreshable' -Value $ThirdItem.isRefreshable
        $APIValue | Add-Member -MemberType NoteProperty -Name 'isOnPremGatewayRequired' -Value $ThirdItem.isOnPremGatewayRequired

        #Add object to array.
        $GatewayObject += $APIValue

    }

}

#Export results to file.
$GatewayObject | ConvertTo-Json | Out-File $FileName

#Export errors file.
$ErrorOutput | ConvertTo-Json | Out-File $ErrorFileName