#Docs for my own reference:
#Primary docs for installation: https://docs.microsoft.com/en-us/powershell/gateway/overview?view=datagateway-ps
#Primary PBI docs: https://powerbi.microsoft.com/en-my/blog/on-premises-data-gateway-management-via-powershell-public-preview/

#Install PBI gateway module.
Install-Module -Name DataGateway -Scope CurrentUser

#Import gateway module.
Import-Module DataGateway

#Login using gateway admin account.
Login-DataGatewayServiceAccount

#Retrieve the list of gateways which you are an admin of.
#Copy the cluster id for RRCSnowflakeODBC.
Get-DataGatewayCluster 

#Run to get permissions data on the gateway.
#Replace id with that of RRCSnowflakeODBC.
Get-DataGatewayCluster -GatewayClusterId 1da235ff-5d0f-41a4-945c-062e07ca307e | Select -ExpandProperty Permissions | Export-Csv "C:\Temp\GatewayClusterInfo.csv" -NoTypeInformation

#Run to get cluster member information.
#Replace id with that of RRCSnowflakeODBC.
Get-DataGatewayCluster -GatewayClusterId 1da235ff-5d0f-41a4-945c-062e07ca307e | Select -ExpandProperty MemberGateways | Export-Csv "C:\Temp\GatewayClusterMembers.csv" -NoTypeInformation

#Get gateway status information.
#Replace id with that of RRCSnowflakeODBC.
Get-DataGatewayClusterStatus -GatewayClusterId 1da235ff-5d0f-41a4-945c-062e07ca307e | Export-Csv "C:\Temp\GatewayClusterStatus.csv" -NoTypeInformation

#Get all gateway data sources.
#Replace id with that of RRCSnowflakeODBC.
Get-DataGatewayClusterDatasource -GatewayClusterId 1da235ff-5d0f-41a4-945c-062e07ca307e | Export-Csv "C:\Temp\GatewayClusterDataSources.csv" -NoTypeInformation

# Not needed, but get all data sources for all clusters.
#Get-DataGatewayCluster | Get-DataGatewayClusterDatasource | Export-Csv "C:\Temp\GatewayClusterDataSources - All.csv" -NoTypeInformation
