#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspace?view=powerbi-ps

#DESCRIPTION: Extract all workspaces via PowerShell and service principal.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "Oem8Q~Vr8ebpcuiFwilfjeSPCMoNqhDtaoIYxbfS"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

     ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspaces.csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Connect to Power BI with credentials of Power BI admin.
#Connect-PowerBIServiceAccount

#Get all workspaces in the organization.
$Result = Get-PowerBIWorkspace -Scope Organization -All

#Format results in tabular format.
$Result | Select-Object Id, Name, IsReadOnly, IsOnDedicatedCapacity, CapacityId, Description, Type, State, IsOrphaned | Export-Csv $FileName