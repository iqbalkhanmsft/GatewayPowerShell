#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing#get-powerbiactivityevent-cmdlet

#DESCRIPTION:
#Returns all Power BI activity log data for the last 30 days.

#REQUIREMENTS:
#Ensure the user authenticating is a Power BI admin.

    ####### PARAMETERS START #######

    $Path = "C:\Temp\WorkspaceCreatedLog.json" #Full directory path where the script output should extract to.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

Connect-PowerBIServiceAccount

30..1 |
foreach {
    $Date = (((Get-Date).Date).AddDays(-$_))
    "$Date"
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss)
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss)
    
    Get-PowerBIActivityEvent -StartDateTime $StartDate -EndDateTime $EndDate -ResultType JsonString | 
    Out-File -FilePath $Path -Append
}

####### END SCRIPT #######