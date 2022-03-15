#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#PowerShell documentation - Connect-AzAccount: https://docs.microsoft.com/en-us/powershell/module/az.accounts/connect-azaccount?view=azps-7.3.2
#PowerShell documentation - Get-AzADUser: https://docs.microsoft.com/en-us/powershell/module/az.resources/get-azaduser?view=azps-7.3.2

####### SCRIPT PARAMETERS #######

#Enter app registration credentials here.
$AppId = "9d241b3d-fb86-41a0-a00d-9bee7b9fd855"
$Secret = ConvertTo-SecureString "z2L7Q~AhRUTnmkm0W3SoounqNK4KP.7QiQpnS" –asplaintext –force
$TenantId = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

#Folder directory where script output will be saved to.
#Either change the directory or create a "Temp" folder under the C:\ drive if one does not already exist.
$Dir = "C:\Temp\AHS - Get All Azure AD Users.csv"

####### SCRIPT MODULES #######

#Uncomment and install as needed. May take some time to download - ~5-10 minutes.
#Install-Module -Name Az

Import-Module -Name Az

####### BEGIN SCRIPT #######

#Takes app registration credentials and creates a PS Credential object.
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $AppId, $Secret

#Connects to Azure AD using PS Credential.
Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $Credential

#Only selects the relevant data for the output.
#Update script with selected columns once verified by AHS team.
$Output = Get-AzADUser | Select *

#Outputs data to the specified directory.
$Output | Export-Csv $Dir -NoTypeInformation -Encoding utf8

Write-Host "Azure AD user output created!"

#Disconnects connection.
Disconnect-AzAccount

#Select City, CompanyName, Country, CreatedDateTime, CreationType, DeletedDateTime, Department, DisplayName, EmployeeHireDate, EmployeeId, EmployeeType, GivenName, Id, JobTitle, Mail, Office Location, PostalCode, Surname, UserPrincipalName