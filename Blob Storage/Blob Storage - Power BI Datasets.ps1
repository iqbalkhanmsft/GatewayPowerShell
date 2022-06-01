#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/invoke-powerbirestmethod?view=powerbi-ps

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.

    ####### PARAMETERS START #######

    $clientID = "c6f7cf55-9159-4e40-a0e0-57bd32ec3e41" #Aka app ID.
    $clientSecret = "-cv8Q~AapvQPuDFLo5E5twpVDm6xIcRkP3cS.bnk"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    $apiUri = "groups/0be252fd-f744-4d90-b1ce-b06c0a2a5f6b/reports"

    $resourceGroup = "pocs"
    $storageAccount = "customerpocsstorage"
    $storageKey = "DSaCoYjnFuoT/jKCt2mkwYP1NXGjm+n9DOuRCO6X7+SUcD2XKKWONRWTQ6i9iXAqVjVzz6BrsnGx+AStjvF7WQ=="
    $containerName = "ch-colorado"

    $file = "C:\Temp\Power BI - Azure Blob Storage Test.csv"

    $fileSave = "Azure Automation Export.csv"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

Set-ExecutionPolicy RemoteSigned

Import-Module Az.Accounts
Import-Module Az.Storage

#Create credentials object using environment parameters.
$password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$credentials = New-Object PSCredential $clientID, $password

#Connect to Power BI with credentialss of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $credentials -Tenant $TenantID

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

$result | Export-Csv $file -NoTypeInformation

Connect-AzAccount -ServicePrincipal -Tenant $tenantID -Credential $credentials

Get-AzStorageAccount -Name $storageAccount -ResourceGroupName $resourceGroup |
Get-AzStorageContainer -Name $containerName |
Set-AzStorageBlobContent -File $file -Blob $fileSave