#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://github.com/microsoft/powerbi-powershell

#DESCRIPTION: Extracts all Power BI workspaces + underlying users by access type.

#Install Power BI modules.
Install-Module -Name MicrosoftPowerBIMgmt

#Login into Power BI.
Login-PowerBIServiceAccount

#Get all workspaces.
Get-PowerBIWorkspace -Scope Organization -All  | 

#For each workspace, return all users and other underlying info; export to file.
ForEach-Object {
$WorkspaceId = $_.Id
$Workspace = $_.Name
$WorkspaceType = $_.Type
$WorkspaceState = $_.State
$IsOnDedicatedCapacity = $_.IsOnDedicatedCapacity
$CapacityId = $_.CapacityId

foreach ($User in $_.Users) {
[PSCustomObject]@{
WorkspaceId = $WorkspaceId
Workspace = $Workspace
WorkspaceType = $WorkspaceType
WorkspaceState = $WorkspaceState
IsOnDedicatedCapacity = $IsOnDedicatedCapacity
CapacityId = $CapacityId
User = $User.AccessRight    
Identifier = $User.Identifier
Type = $User.PrincipalType
                }
                            }

} | Export-CSV "C:\Temp\WorkspaceUsers.csv" -NoTypeInformation