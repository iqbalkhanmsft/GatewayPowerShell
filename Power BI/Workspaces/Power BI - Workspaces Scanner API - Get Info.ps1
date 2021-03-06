#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin

#DESCRIPTION: Extract all workspaces via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "5An8Q~CcQJOqUZCuUZprB1KLbnZBDjWuNyWZ1b3Q"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run.
    $ApiUri = "admin/workspaces/getInfo"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspaces (API).json"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

$Result = Invoke-PowerBIRestMethod -Url $ApiUri -Method Post

#Format results in tabular format.
$Result #| Out-File $FileName