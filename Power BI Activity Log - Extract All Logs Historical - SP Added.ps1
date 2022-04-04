#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/power-bi/admin/service-admin-auditing#get-powerbiactivityevent-cmdlet

#DESCRIPTION:
#Returns all Power BI activity log data for the last 30 days.
#Adds login via service principal.

#REQUIREMENTS:
#Ensure the user authenticating is a Power BI admin.

    ####### PARAMETERS START #######

    #Force install if already installed.
    #Install-Module -Name MicrosoftPowerBIMgmt -Force

    #File path.
    $Path = "C:\Temp\WorkspaceCreatedLog.json" #Full directory path where the script output should extract to.

    #Environment variables.
    $AppId = "e824a23c-ca9c-4cf7-a765-e1a65c0864e3"
    $TenantId = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $ClientSecret = "zWm7Q~zIoqqugzhUF4Zd6KcoOvuwIlpyQYmHL" 

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create secure string & credential for application id and client secret.
$PbiSecurePassword = ConvertTo-SecureString $ClientSecret -Force -AsPlainText
$PbiCredential = New-Object Management.Automation.PSCredential($AppId, $PbiSecurePassword)

#Connect to the Power BI service.
Connect-PowerBIServiceAccount -ServicePrincipal -TenantId $TenantId -Credential $PbiCredential

#Run loop for the last 30 days to extract activity log data.
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