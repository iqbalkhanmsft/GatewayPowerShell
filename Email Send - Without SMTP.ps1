#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#PowerShell documentation: https://docs.microsoft.com/en-us/powershell/module/datagateway/?view=datagateway-ps

#Runs script to get the status of any offline gateway members across the organization (or for a specific cluster).
#Sends an automated email message via PowerShell without using an SMTP server; uses the existing Outlook application.
#Only sends the email if there are at least one gateway members offline.

#Remaining: 
#Identify primary, change gateway type labeling, change member state labeling.
#Scheduling script via Task Scheduler.

####### PARAMETERS START #######

    ####### GATEWAY PARAMETERS #######

    #Enter app registration credentials for Power BI here.
    $AppId = "cde24cf1-620a-4d1f-82ee-44b2138e8002"
    $Secret = ConvertTo-SecureString "zBG7Q~MYyle3PtGzDazYJ0lGqPgb0.4RNN7mS" –asplaintext –force
    $TenantId = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    #Gets date in UTC + underscore format to be appended into file output name.
    $Date = Get-Date -Format "MM_dd_yyyy hh_mm" -AsUTC

    #Folder directory where the script output will be saved. Also the directory of the email attachment.
    #Either change the directory or create a "Temp" folder under the C:\ drive if one does not already exist.
    $File = "C:\Temp\Gateway Status Update " + $Date + " UTC.csv"

    #Specific cluster ID for which gateway member statuses will be returned.
    #Commented out as current script scans for the status of ALL gateway members in the entire tenant.
    #$ClusterId = "XXXXXXXXXXXX"

    ####### EMAIL PARAMETERS #######

    #Create an instance of Outlook.
    $Outlook = New-Object -ComObject Outlook.Application

    $Mail = $Outlook.CreateItem(0) #Create Outlook object.
    $Mail.To = "iqbalkhan@microsoft.com" #Primary email recipients. Add in X; Y; Z format if multiple recipients.
    #$Mail.Cc = "iqbalkhan@microsoft.com" #CC email recipients, commented out for now.
    $OneGatewaySubject = "A gateway in your organization is offline!" #Subject if one gateway member is offline.
    $MultipleGatewaysSubject = "Multiple gateways in your organization are offline!" #Subject if multiple gateway members are offline.

####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Utilize app registration credentials with Tenant.Read.All permissions for the Power BI service.
Connect-DataGatewayServiceAccount -ApplicationId $AppId -ClientSecret $Secret -TenantId $TenantId

#Returns the member statuses for ALL clusters in the organization.
$Members = Get-DataGatewayCluster -Scope Organization | Select @{name="PrimaryId";expression={$_.Id}}, @{name="PrimaryName";expression={$_.Name}}, @{name="GatewayDescription";expression={$_.Description}}, @{name="GatewayType";expression={$_.Type}} -ExpandProperty MemberGateways

#Returns gateway member information for the specified cluster.
#Commented out in place of the tenant-wide option above.
#$Members = Get-DataGatewayCluster -GatewayClusterId $ClusterId | Select -ExpandProperty MemberGateways

#Only selects the relevant data for the output.
#Change if any additional information is desired.

$Output = $Members | Select @{name="MemberId";expression={$_.Id}}, @{name="MemberName";expression={$_.Name}}, @{name="MemberState";expression={$_.State}}, @{name="MemberVersion";expression={$_.Version}}, PrimaryId, PrimaryName, GatewayDescription, GatewayType

#Only stores gateway members that are offline.
$OfflineGateways = $Output | Where MemberState -NotContains "Enabled"

#Counts the # of members that are not live.
#Used below to decide whether an email should be sent.
$OfflineGatewayCount = $OfflineGateways.Count

#If at least one gateway member is offline, export the data to file.
if ($OfflineGatewayCount -ge 1) {

    Write-Host "At least one gateway member is offline; writing data to file."
    $OfflineGateways | Export-Csv $File -NoTypeInformation -Encoding utf8
    Write-Host "Now sending out the email..."

}

#If no gateways are offline, do not export any data.
#Process is exited.

else {

    Write-Host "All gateway members are online; no data will be written to file."
    Write-Host "Exiting the process now..."
    Exit

}

#Disconnects connection.
Disconnect-DataGatewayServiceAccount

####### END SCRIPT #######

#Documentation: http://techyguy.in/powershell-script-to-send-an-email-without-an-smtp-server/

#If multiple gateways are offline, then utilize the multiple gateway subject.
if ($OfflineGatewayCount -gt 1) {

    $Mail.Subject = $MultipleGatewaysSubject

}

#If only one gateway member is offline, use the single gateway subject.
if ($OfflineGatewayCount -eq 1) {

    $Mail.Subject = $OneGatewaySubject

}

#Body of email - lists out the gateway members that are offline.
$Mail.Body = "The following gateway(s) are offline: " + $OfflineGateways.MemberName + ". See the attached document for more information."

#If at least one gateway member is offline, send email.

$Mail.Attachments.Add($file)
$Mail.Send()
Write-Host "Mail sent successfully!"
Exit