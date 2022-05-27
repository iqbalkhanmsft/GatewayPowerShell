#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/cancel-refresh-in-group

#DESCRIPTION: Cancel dataset refresh using manual login.

#Run this DMV first in DAX Studio to get refresh IDs: https://docs.microsoft.com/en-us/openspecs/sql_server_protocols/ms-ssas/94f5a668-857e-47c1-814e-ecd05ef93c96

    ####### PARAMETERS START #######

    $groupId = "c1533552-bcc6-463c-af77-b63f1e418d53"
    $datasetId = "ff77ed8c-2fd4-47c9-9b15-b705da54efb1"
    $apiUri = "datasets/$datasetId/refreshes"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount

#Execute rest method.
$results = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-JSON

#Only store value of oData returned output.
$resultsValue = $results.value

#Show results in a table format.
$resultsValue | Format-Table

#Run if any issues.
#Resolve-PowerBIError -Last

255b7025-f232-480d-b1ec-0277ee269729 1264318030 Scheduled   5/24/2022 3:04:07 PM  Unknown
a636fa4a-c066-755d-fd8e-dd7f8a9804a4 1264243406