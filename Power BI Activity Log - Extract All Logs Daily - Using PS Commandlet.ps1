#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.admin/get-powerbiactivityevent?view=powerbi-ps

#DESCRIPTION:
#Returns all Power BI activity log data for yesterday only.
#Specifically exports data in CSV format; whereas JSON is the default format.

    ####### PARAMETERS START #######

    #Environment parameters.
    $TenantID = '84fb42a1-8f75-4c94-9ea6-0124b5a276c5' #Tenant id.
    $ApplicationID = 'db2c307a-be4f-46bf-894a-f148653df596' #App id.
    $Secret = 'ohc7Q~vBwjskuKrZTBEe4UBUos9fo4PKw-m3U' #Client secret.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $Secret -AsPlainText -Force
$Credential = New-Object PSCredential $ApplicationID, $password

#Connect to Power BI with credentials of Service Principal.
#When using a Service Principal, TenantID must be provided.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#For yesterday only, get all Power BI activity log data.
1..1 |
foreach {

    $Date = (((Get-Date).Date).AddDays(-$_)) #Today's date.
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss) #Beginning of day - yesterday.
    $FileDate = (Get-Date -Date ($StartDate) -Format yyyy-MM-dd) #Given day in simplified format for use in filename.
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss) #End of day - yesterday.

    Write-Output "Exporting data for $FileDate..."
    
    #Run query for yesterday only; convert output from JSON - then manually select via CSV to maintain column order across files.
    (Get-PowerBIActivityEvent -StartDateTime $StartDate -EndDateTime $EndDate -ResultType JsonString | ConvertFrom-Json) | 
    Select Id, RecordType, CreationTime, Operation, OrganizationId, UserType, UserKey, Workload, UserId, 
    ClientIP, UserAgent, Activity, ItemName, WorkSpaceName, DashboardName, DatasetName, ReportName, CapacityId, CapacityName, 
    WorkspaceId, ObjectId, DashboardId, DatasetId, ReportId, AppName, AppReportId, IsSuccess, ReportType, RequestId, ActivityId, DistributionMethod, ConsumptionMethod, DataflowName, DataflowId, DataflowType
    | Export-Csv -NoTypeInformation -Path "C:\Temp\PBI Activity Log - $FileDate.csv" #Export to CSV using date as file name.

    Write-Output "Data export for $FileDate completed. Exiting script..."

}

####### END SCRIPT #######