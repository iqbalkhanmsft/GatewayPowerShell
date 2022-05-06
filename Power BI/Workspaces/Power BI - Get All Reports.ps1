#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspace?view=powerbi-ps

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.

    ####### PARAMETERS START #######

    $ClientID = "f9f34dda-95cc-4cd6-9984-ea90eff20de3" #Aka app ID.
    $ClientSecret = "MMI8Q~6NQ8jrgNxEVsUj83R6Pfxec1DdynO8PdlH"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

     ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $File + "Power BI - All Workspaces.csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Utiliize PS commandlets instead of REST API due to throttling cap on the API call for the admin groups call.
$Result = Get-PowerBIWorkspace -Scope Organization -Filter "(name) eq 'DP DEV'"

# Loop for each workspace ID and each underlying report, return data.
$Reports = ForEach ($Workspace in $Result)
    {
    ForEach ($Report in (Get-PowerBIReport -Scope Organization -WorkspaceId $workspace.Id))
        {
        [pscustomobject]@{
            WorkspaceName = $Workspace.Name 
            WorkspaceID = $Workspace.Id
            WorkspaceDescription = $Workspace.Description
            UsingCapacity = $Workspace.IsOnDedicatedCapacity
            CapacityID = $Workspace.CapacityId
            WorkspaceState = $Workspace.State
            WorkspaceType = $Workspace.Type
            ReportId = $Report.Id
            ReportName = $Report.Name
            ReportDatasetID = $Report.DatasetId
            ReportURL = $Report.WebUrl
            }
        }
    }

#Format results in tabular format.
$Reports #| Export-Csv $fileName