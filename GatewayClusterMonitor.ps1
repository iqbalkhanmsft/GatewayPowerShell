#Install-Module DataGateway

Import-Module -Name DataGateway

$AppId = "cde24cf1-620a-4d1f-82ee-44b2138e8002"
$Secret = ConvertTo-SecureString "zBG7Q~MYyle3PtGzDazYJ0lGqPgb0.4RNN7mS" –asplaintext –force
$Tenant = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

Login-DataGateway -ApplicationId $AppId -ClientSecret $Secret -Tenant $Tenant

Get-DataGatewayCluster -Scope Organization | SELECT -ExpandProperty MemberGateways