#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/reportroot-getonedriveusageaccountdetail?view=graph-rest-1.0#code-try-1

#DESCRIPTION: #Script exports the OneDrive Usage Account Detail report to file.

    ####### PARAMETERS START #######

    $clientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $clientSecret = "lEA8Q~6ANGmydjdfooumFuVfyzXmtMpIToW5rbrC"
    $tenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $file = "C:\Temp\" #Change based on where the file should be saved to.

    $periodValue = "D180"

    ####### PARAMETERS END #######
    
####### BEGIN SCRIPT #######

#Create complete file name.
$fileName = $file + "OneDrive - Usage Report.csv"

#Install module as necessary.
#Install-Module MSAL.PS -Scope CurrentUser -Force

#Import module.
Import-Module MSAL.PS

#Get Graph token.
$MsalToken = Get-MsalToken -TenantId $tenantId -ClientId $clientID -ClientSecret ($clientSecret | ConvertTo-SecureString -AsPlainText -Force)
 
#Connect to Graph using token.
Connect-Graph -AccessToken $MsalToken.AccessToken

#Export report.
Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/reports/getOneDriveUsageAccountDetail(period='D180')" -OutputFilePath $fileName