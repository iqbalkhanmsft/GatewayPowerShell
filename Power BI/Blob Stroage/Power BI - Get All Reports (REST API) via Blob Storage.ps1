#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/reports-get-reports-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/azure.storage/set-azurestorageblobcontent?view=azurermps-6.13.0
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/azurerm.storage/get-azurermstorageaccountkey?view=azurermps-6.13.0
#DOCUMENTATION: https://savilltech.com/2018/03/25/writing-to-files-with-azure-automation/

#DESCRIPTION: Extract all reports via REST API and service principal. Writes data to Blob Storage.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d"
    $ClientSecret = "kTg8Q~279iNcrmu9BndMf2o-gV4LIZUEVCPjPdyn"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run.
    $ApiUri = "admin/reports"

	#Azure Blob Storage credentials.
	$StorageAccount = "customerpocsstorage"
	$ContainerName = "ch-colorado"
	$ResourceGroupName = "customerpocs"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Reports (API).json"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Execute REST API call.
$Result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get

#Setup file name for saving.
$FileName = "Power BI - All Reports (API) - LOCAL BLOB STORAGE.json"
Write-Output "Writing results to $FileName..."

#Format results in tabular format.
$Result | Out-File $FileName

#Import Az modules.
Import-Module -Name Az.Accounts
Import-Module -Name Az.Storage

#Gets first storage key from respective storage account and resource group.
$AccountKey = (Get-AzStorageAccountKey -AccountName $StorageAccount -ResourceGroupName $ResourceGroupName).Value[0]

#Connects to the storage account using context.
$StorageContext = New-AzStorageContext -StorageAccountName $StorageAccount -StorageAccountKey $AccountKey

#Copies API output file to blob storage.
Set-AzStorageBlobContent -File $FileName -Container $ContainerName -BlobType "Block" -Context $StorageContext -Verbose

#Uninstall-Module -Name AzureRM