#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/invoke-powerbirestmethod?view=powerbi-ps

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.

    ####### PARAMETERS START #######

    $clientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $clientSecret = "zuu8Q~DKMUxO~DYrznB6Xx8PInlGmXRFxk9Kyb3p"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Url for relevant query to run.
    $apiUri = "groups/0be252fd-f744-4d90-b1ce-b06c0a2a5f6b/reports"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Uncomment and run if not installed once before.
#Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

#Update module if previously installed and is out of date.
#Update-Module -Name Az

Import-Module -Name AzureRM.Storage

Get-Module -Name Az.Storage | select -ExpandProperty ExportedCommands

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $clientID, $password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

$context = New-AzureStorageContext -StorageAccountName "customerpocsstorage " -StorageAccountKey "BlodtbT2+HdPgECZ8wBSqapbMy1A28SbPjndjYaW64nObYccMXnArIvJpp1T5TLJOzpggwO7+ltq0ILsfEEtEw=="

$result | Export-Csv $context\ch-colorado\PowerBI-Datasets.csv -NoTypeInformation