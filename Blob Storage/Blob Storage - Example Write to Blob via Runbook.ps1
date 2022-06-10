#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/invoke-powerbirestmethod?view=powerbi-ps

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    $apiUri = "groups/0be252fd-f744-4d90-b1ce-b06c0a2a5f6b/reports"

    #Storage account info.
    $resourceGroup = "pocs"
    $storageAccount = "customerpocstorage"
    $containerName = "ch-colorado"
    $subscription = "f29abab0-37b7-4f91-831b-d02d5cd80d7b"

    #Temporary file to save.
	$file = "Azure Blob Storage Stage.csv"

    #End result file to save in Blob Storage.
    $fileSave = "Azure Blob Storage Final.csv"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Unneeded for typical execution:
#Set-ExecutionPolicy RemoteSigned
#Update-Module Az

#Remove all modules from session.
Get-Module | Remove-Module -Force

#Import Az accounts module.
Import-Module Az.Accounts #-NoClobber

#Import Az storage module.
Import-Module Az.Storage #-NoClobber

#Create credentials object using environment parameters.
$password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credentials = New-Object PSCredential $clientID, $password

#Connect to Power BI with credentialss of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credentials -Tenant $TenantID

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

#Store API results to file.
$result | Export-Csv $file -NoTypeInformation

#Connect to Az account using Service Principal.
Connect-AzAccount -ServicePrincipal -Tenant $tenantID -Credential $credentials -Subscription $Subscription

#Connect to Az account using manual authentication.
#Connect-AzAccount -Tenant $tenantID -Subscription $Subscription

#Use credentials to write result to blob.
Get-AzStorageAccount -Name $storageAccount -ResourceGroupName $resourceGroup |
Get-AzStorageContainer -Name $containerName |
Set-AzStorageBlobContent -File $file -Blob $fileSave