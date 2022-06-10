#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/reports-get-reports-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/reports-get-report-users-as-admin

#DESCRIPTION: Extract all reports and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "dih8Q~J.MvNuTB5PLUwuYcJOFzQuLmhMKOemZdkE"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run.
    $ApiUri = "admin/reports"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Reports + Users (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store reports and parsed user info to.
$ReportsObject = @()

#Since a report may have multiple users, split users out into individual records. #For each report...
ForEach($Item in $ResultValue) {

    #Store report ID for use in reports API below.
    $reportId = $Item.id

    #Execute reports API for the given report ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/reports/$reportId/users" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add app info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportType' -Value $Item.reportType
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportName' -Value $Item.name
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportUrl' -Value $Item.webUrl
    $APIValue | Add-Member -MemberType NoteProperty -Name 'datasetId' -Value $Item.datasetId
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportCreatedDate' -Value $Item.createdDateTime
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportModifiedDate' -Value $Item.modifiedDateTime
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportmodifiedBy' -Value $Item.modifiedBy
    $APIValue | Add-Member -MemberType NoteProperty -Name 'reportcreatedBy' -Value $Item.createdBy

    #Add object to array.
    $ReportsObject += $APIValue

}

#Format results in tabular format.
$ReportsObject | Export-Csv $FileName