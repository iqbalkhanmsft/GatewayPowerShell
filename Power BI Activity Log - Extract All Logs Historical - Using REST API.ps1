#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://www.powershellgallery.com/packages/MicrosoftPowerBIMgmt

#DESCRIPTION: Extracts all Power BI activity log data for last 29 days.

    ####### PARAMETERS START #######

    #Number of days for which to collect activity logs, in iterations of 1 day at a time.
    $MaxDays = 30
    $MinDays = 2

    #Folder directory of where to store files.
    $Path = "C:\Temp\"

    #Environment parameters.
    $TenantID = '84fb42a1-8f75-4c94-9ea6-0124b5a276c5' #Tenant id.
    $ApplicationID = 'e824a23c-ca9c-4cf7-a765-e1a65c0864e3' #App id.
    $Secret = '74Q7Q~eXa6stbN-ZLIZAoq6fjL~ZwtBObhDnQ' #Client secret.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $Secret -AsPlainText -Force
$Credential = New-Object PSCredential $ApplicationID, $password

#Connect to Power BI with credentials of Service Principal.
#When using a Service Principal, TenantID must be provided.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Get bearer token.
$Header = Get-PowerBIAccessToken

#MaxDays..MinDays, loops over as an array over every object.
$MaxDays..$MinDays |
ForEach-Object {
    $Date = (((Get-Date).Date).AddDays(-$_))
    
    #API only accepts a specific datetime format.
    $StartDate = (Get-Date -Date ($Date) -Format yyyy-MM-ddTHH:mm:ss)
    $EndDate = (Get-Date -Date ((($Date).AddDays(1)).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ss)
    
    #Creates an empty array to store all records for the current day in context.
    $activities = @()        

    #Initiate the first call to the API, the field continuationURI will be used to continue the same session for the next batch of results.
    $auditlogs = Invoke-PowerBIRestMethod -Url "https://api.powerbi.com/v1.0/myorg/admin/activityevents?startDateTime='$StartDate'&endDateTime='$EndDate'" -Method Get | ConvertFrom-Json

    #Store first batch of events using activities array.
    $activities += $auditlogs.activityEventEntities

    #When continuationUri is NULL (blank), all records for the current day in context have been retrieved.
    if($auditlogs.continuationUri) {
        do {
            $auditlogs = Invoke-PowerBIRestMethod -Url $auditlogs.continuationUri -Method Get | ConvertFrom-Json
            $activities += $auditlogs.activityEventEntities
        } until(-not $auditlogs.continuationUri)    
    }
    
    #Select data from object.
    $selectedActivities = $activities | Select-Object Id, RecordType, CreationTime, Operation, OrganizationId, UserType, UserKey, Workload, UserId, 
    ClientIP, UserAgent, Activity, ItemName, WorkSpaceName, DashboardName, DatasetName, ReportName, CapacityId, CapacityName, 
    WorkspaceId, ObjectId, DashboardId, DatasetId, ReportId, AppName, AppReportId, IsSuccess, ReportType, RequestId, ActivityId, DistributionMethod, ConsumptionMethod, DataflowName, DataflowId, DataflowType
    
    #Create the file name for current day in context, and export the results to a .csv file.
    $fileName = "$(Get-Date -Date $Date -Format yyyyMMdd).csv"
    $filePath = "$($Path)$($fileName)"

    #Export results.
    $selectedActivities | Export-Csv -Path $filePath -NoTypeInformation -Encoding UTF8 -Force
}

####### END SCRIPT #######