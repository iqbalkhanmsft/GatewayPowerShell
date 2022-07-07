#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.workspaces/get-powerbiworkspace?view=powerbi-ps

#DESCRIPTION: Returns the total number of workspaces in the organization.

####### BEGIN SCRIPT #######

#Connect to Power BI with credentials of a Power BI admin.
Connect-PowerBIServiceAccount -Environment USGov

#Extract all workspaces in the organization using the Power BI PS comamndlet.
$Result = Get-PowerBIWorkspace -Scope Organization -All

#Store the total number of records returned.
$TotalWorkspaces = $Result.Count

#Display output.
Write-Output "This organization has $TotalWorkspaces total workspaces..."