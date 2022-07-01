#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/data-integration/gateway/service-gateway-powershell-support

#DESCRIPTION: Extracts status of gateway members. Needs to be run in PS 7x+.

    ####### PARAMETERS START #######

    #Service principal parameters.
    $ClientID = "46f313be-6b15-4d2c-a54a-ef0d049247e8" #Aka app ID.
    $ClientSecret = "X5b8Q~yZcinj4s2SM6LlEfGN842YAqI6yhhCYbYU"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #File directory to store data.
    $File = "C:\Temp\"

    #File name to store data as.
    $FileName = "Power BI - Get Gateway Cluster Status.json" 

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Specifically for PS 7. PS 5 has a different gateway module.
#Install-Module -Name DataGateway

#Remove imported modules if any remain in cache.
#Get-Module | Remove-Module -Force

#Import module.
Import-Module -Name DataGateway

#Create credentials object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force

#Connect to gateway portal with credentials of service principal.
Login-DataGatewayServiceAccount -ApplicationId $ClientID -ClientSecret $Password -Tenant $TenantID

#Gets all gateway clusters that Service Principal is an admin of.
#Get-DataGatewayCluster

#Gets status of specific gateway cluster.
$Output = Get-DataGatewayClusterStatus -GatewayClusterId 0dd36b25-1652-44b7-af60-86c87835f266 | ConvertTo-Json

#Create complete file name and directory where output will be saved.
$Export = $File + $FileName

#Start script here.
$Output | Out-File $Export