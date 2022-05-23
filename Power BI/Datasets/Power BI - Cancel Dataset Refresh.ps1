#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/cancel-refresh-in-group

#DESCRIPTION: Cancel dataset refresh using manual login.

#Run this DMV first in DAX Studio to get refresh IDs: https://docs.microsoft.com/en-us/openspecs/sql_server_protocols/ms-ssas/94f5a668-857e-47c1-814e-ecd05ef93c96

    ####### PARAMETERS START #######

    $groupId = "c1533552-bcc6-463c-af77-b63f1e418d53"
    $datasetId = "ff77ed8c-2fd4-47c9-9b15-b705da54efb1"
    $refreshId = "03404ac3-18ae-47da-a085-bd80eddd3870"

    #DELETE https://api.powerbi.com/v1.0/myorg/groups/{groupId}/datasets/{datasetId}/refreshes/{refreshId}
    $apiUri = "groups/$groupId/datasets/$datasetId/refreshes/$refreshId"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Connect to Power BI with credentials of Service Principal.
#Connect-PowerBIServiceAccount

#Execute rest method.
Invoke-PowerBIRestMethod -Url $apiUri -Method Delete

Write-Output "Refresh `$refreshId for Power BI dataset $datasetId in workspace $groupId deleted..."

#Run if errors.
#Resolve-PowerBIError -Last