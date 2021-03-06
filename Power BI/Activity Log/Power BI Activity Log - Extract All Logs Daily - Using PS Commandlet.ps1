#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.admin/get-powerbiactivityevent?view=powerbi-ps

#DESCRIPTION:
#Returns all Power BI activity log data for yesterday only.
#Specifically exports data in CSV format; whereas JSON is the default format.

    ####### PARAMETERS START #######

    #Environment parameters.
    $ClientID = "91d4c088-3bcf-46bb-89b0-9de5356c8e88" #Aka app ID.
    $ClientSecret = "Cg78Q~.3n_Mm4RmaQdYg1LAwQYZ1btgpQpCjfbj8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $password

#Connect to Power BI with credentials of Service Principal.
#When using a Service Principal, TenantID must be provided.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Connect to Power BI using a Power BI admin account + OAuth.
#Commented out in place of Service Principal login above.
#Connect-PowerBIServiceAccount

#For yesterday only, get all Power BI activity log data.
1..1 |
foreach {

    $Date = (((Get-Date).Date).AddDays(-$_)) #Today's date.
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss) #Beginning of day - yesterday.
    $FileDate = (Get-Date -Date ($StartDate) -Format yyyy-MM-dd) #Given day in simplified format for use in filename.
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss) #End of day - yesterday.

    Write-Output "Exporting data for $FileDate..."

    #Setup file name for saving.
    $FileName = $File + "PBI Activity Log - $FileDate.csv"
    Write-Output "Writing results to $FileName..."
    
    #Run query for yesterday only; convert output from JSON - then manually select via CSV to maintain column order across files.
    (Get-PowerBIActivityEvent -StartDateTime $StartDate -EndDateTime $EndDate -ResultType JsonString | ConvertFrom-Json) | 
    Select Id, RecordType, CreationTime, Operation, OrganizationId, UserType, UserKey, Workload, UserId, 
    ClientIP, UserAgent, Activity, ItemName, WorkSpaceName, ReportName, WorkspaceId, ObjectId, ReportId, 
    IsSuccess, ReportType, RequestId, ActivityId, DistributionMethod | Export-Csv -NoTypeInformation -Path $FileName #Export to CSV using date as file name.

    Write-Output "Data export for $FileDate completed. Exiting script..."

}

####### END SCRIPT #######