#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.admin/get-powerbiactivityevent?view=powerbi-ps

#DESCRIPTION:
#Returns all Power BI activity log data from 30 days prior through the day before yesterday.
#Specifically exports data in CSV format; whereas JSON is the default format.

####### BEGIN SCRIPT #######

#Connect to Power BI as a Power BI admin.
Connect-PowerBIServiceAccount

#For the last 30 days through the day before yesterday, get all Power BI activity log data - incrementally for one day at a time.
30..2 |
foreach {

    $Date = (((Get-Date).Date).AddDays(-$_)) #Today's date.
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss) #Beginning of given day.
    $FileDate = (Get-Date -Date ($StartDate) -Format yyyy-MM-dd) #Given day in simplified format for use in file name.
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss) #End of given day.

    Write-Output "Exporting data for $FileDate..."
    
    #Run query for givern day; convert from JSON - then manually select via CSV to maintain column order across files.
    (Get-PowerBIActivityEvent -StartDateTime $StartDate -EndDateTime $EndDate -ResultType JsonString | ConvertFrom-Json) | 
    Select Id, RecordType, CreationTime, Operation, OrganizationId, UserType, UserKey, Workload, UserId, 
    ClientIP, UserAgent, Activity, ItemName, WorkSpaceName, ReportName, WorkspaceId, ObjectId, ReportId, 
    IsSuccess, ReportType, RequestId, ActivityId, DistributionMethod | Export-Csv -NoTypeInformation -Path "C:\Temp\PBI Activity Log - $FileDate.csv" #Export to CSV using date as file name.

    Write-Output "Data export for $FileDate completed. Moving to next day..."

}

####### END SCRIPT #######