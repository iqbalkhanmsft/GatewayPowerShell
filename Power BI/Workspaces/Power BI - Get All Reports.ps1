#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspace?view=powerbi-ps

#DESCRIPTION: Extract all Power BI reports per workspace.

    ####### PARAMETERS START #######

    $ClientID = "f9f34dda-95cc-4cd6-9984-ea90eff20de3" #Aka app ID.
    $ClientSecret = "MMI8Q~6NQ8jrgNxEVsUj83R6Pfxec1DdynO8PdlH"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

     ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Reports.csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Connect to Power BI using a Power BI admin account + OAuth.
#Commented out in place of Service Principal login above.
#Connect-PowerBIServiceAccount

#Get all workspaces in the organization.
$Result = Get-PowerBIWorkspace -Scope Organization

#For each workspace ID in the previous output, loop through all underlying reports.
$Reports = ForEach ($Workspace in $Result)
    {
    ForEach ($Report in (Get-PowerBIReport -Scope Organization -WorkspaceId $Workspace.Id))
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
$Reports | Export-Csv $FileName