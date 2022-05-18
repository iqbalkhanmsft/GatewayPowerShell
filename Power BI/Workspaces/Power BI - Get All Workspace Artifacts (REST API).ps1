#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin
#DOCUMENTATION: https://powerbi.microsoft.com/en-us/blog/avoiding-workspace-loops-by-expanding-navigation-properties-in-the-getgroupsasadmin-api/

#DESCRIPTION: Extract all workspaces + all artifacts via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "kTg8Q~279iNcrmu9BndMf2o-gV4LIZUEVCPjPdyn"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run.

    $ApiUri = "admin/groups?$top=5000&$skip=5000&$expand=users,reports,dashboards,datasets"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspace Artifacts (API).json"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#REMOVE ENVIRONMENT.
#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Execute workspaces PS command.
#$Workspaces = Get-PowerBIWorkspace -Scope Organization

#Total number of workspaces.
#$TotalWorkspaces = $Workspaces.Count

#Number of batches (5000) that the script should be executed.
#$WorkspacesIndex = $TotalWorkspaces / 5000

#Round number of executions up.
#$Loops = [math]::ceiling($WorkspacesIndex)

#Write-Output "The organization has $TotalWorkspaces total workspaces..."
#Write-Output "The script will be run $Loops time(s)..."

#Total number of workspaces. DELETE
$TotalWorkspaces = 5000

#Number of batches (5000) that the script should be executed. DELETE
$WorkspacesIndex = $TotalWorkspaces / 5000

#Round number of executions up. delete
$Loops = [math]::ceiling($WorkspacesIndex)

#DELETE BOTH.
Write-Output "The organization has $TotalWorkspaces total workspaces..."
Write-Output "The script will be run $Loops time(s)..."

#Counter for loop.
$Index = 1

if ($TotalWorkspaces -le 5000)
{
    $Skip = 0
    $Result = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get
}

elseif ($TotalWorkspaces -gt 5000)
{
    do
    {
        $Skip = 5000 * $Index
        $Incremental = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get
        $Result += $Incremental
        $Index++
        Write-Output "Extracting batch # $Index..."

    } until ($Index -ge $Loops)
}

#Format results in tabular format.
$Result | Out-File $FileName

#$Index = 0
#$Skip = 0
