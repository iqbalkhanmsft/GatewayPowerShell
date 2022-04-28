#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#PowerShell documentation: https://docs.microsoft.com/en-us/powershell/module/datagateway/?view=datagateway-ps

####### SCRIPT PARAMETERS #######

#Enter app registration credentials here.
$AppId = "cde24cf1-620a-4d1f-82ee-44b2138e8002"
$Secret = ConvertTo-SecureString "zBG7Q~MYyle3PtGzDazYJ0lGqPgb0.4RNN7mS" –asplaintext –force
$TenantId = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

#Folder directory where script output will be saved to.
#Either change the directory or create a "Temp" folder under the C:\ drive if one does not already exist.
$Dir = "C:\Temp\DHS OHA - Gateway Member Status Output.csv"

#Specific cluster ID for which member statuses will be returned.
#Can leave as-is if using the alternative script further below which returns the status of gateway members for ALL clusters in the tenant.
$ClusterId = "860118ae-edee-4fbb-8697-579c89115c31"

####### BEGIN SCRIPT #######

#Utilize app registration credentials with Tenant.Read.All permissions for the Power BI service.
Connect-DataGatewayServiceAccount -ApplicationId $AppId -ClientSecret $Secret -TenantId $TenantId

#Could use the below option if you are a Power BI admin, O365 tenant admin, or Power Platform admin.
#This would return the member statuses for ALL clusters in the organization, not just the specified cluster.
#$Members = Get-DataGatewayCluster -Scope Organization | Select -ExpandProperty MemberGateways

#Returns gateway member information for the specified cluster. Comment out if using the above option.
$Members = Get-DataGatewayCluster -GatewayClusterId $ClusterId -Scope Organization | Select -ExpandProperty MemberGateways

#Only selects the relevant data for the output.
$Output = $Members | Select Id, Name, Status, Version, State, VersionStatus

#Outputs data to the specified directory.
$Output | Export-Csv $Dir -NoTypeInformation -Encoding utf8

Write-Host "Gateway status output completed!"

#Disconnects connection.
Disconnect-DataGatewayServiceAccount

####### END SCRIPT #######