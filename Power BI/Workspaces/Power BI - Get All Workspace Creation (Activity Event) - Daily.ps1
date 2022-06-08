#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.admin/get-powerbiactivityevent?view=powerbi-ps

#DESCRIPTION:
#Returns all Power BI activity log data (specifically workspace creation) for yesterday only.
#Exports data in CSV format.

    ####### PARAMETERS START #######

    #Environment parameters.
    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = 'Wbu8Q~nagEWCptHuQDVXsGAgIwnOwX~Pj_3bFdBO' #Client secret.
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"

    $File = "C:\Temp\" #Change based on where the file should be saved.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Connect to Power BI using a Power BI admin account + OAuth.
#Commented out in place of Service Principal login above.
#Connect-PowerBIServiceAccount

#For yesterday only, get all Power BI activity log data (specifically workspace creation).
1..1 |
foreach {

    $Date = (((Get-Date).Date).AddDays(-$_)) #Given date.
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss) #Beginning of yesterday.
    $FileDate = (Get-Date -Date ($StartDate) -Format yyyy-MM-dd) #Given day in simplified format for use in file name.
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss) #End of yesterday.

    Write-Output "Exporting data for $FileDate..."

    #Setup file name for saving.
    $FileName = $File + "PBI Activity Log - Workspaces Created - $FileDate.csv"
    Write-Output "Writing results to $FileName..."
   
    #Run Power BI activity event query for given day to extract workspace creation logs.
    (Get-PowerBIActivityEvent -StartDateTime $StartDate -EndDateTime $EndDate -ActivityType CreateGroup -ResultType JsonString | ConvertFrom-Json) | 
    Select * | Export-Csv -NoTypeInformation -Path $FileName #Export to CSV using date as file name.

    Write-Output "Data export for $FileDate completed. Exiting script..."

}

####### END SCRIPT #######