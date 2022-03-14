
#Enter app registration credentials here.
$AppId = "cde24cf1-620a-4d1f-82ee-44b2138e8002"
$Secret = ConvertTo-SecureString "zBG7Q~MYyle3PtGzDazYJ0lGqPgb0.4RNN7mS" –asplaintext –force
$TenantId = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

#Enter in credentials for app registration with Tenant.Read.All permissions for the Power BI service.
Connect-DataGatewayServiceAccount -ApplicationId $AppId -ClientSecret ($Secret -AsSecureString) -TenantId $TenantId

#PowerShell documentation: https://docs.microsoft.com/en-us/powershell/module/datagateway/?view=datagateway-ps

#Could also use -Scope Organization if you are a Power BI admin, O365 tenant admin, or Power Platform admin.
Get-DataGatewayCluster -Scope Organization | Select -ExpandProperty MemberGateways

Disconnect-DataGatewayServiceAccount