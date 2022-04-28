#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/reports/get-reports-in-group

#DESCRIPTION: Authenticate to the Power BI tenant using authentication login.

    ####### PARAMETERS START #######

    $file = "C:\Temp\" #Change based on where the data export should be saved.

    $workspaceId = "01414aaa-5eaf-41cd-8974-443f114bc034" #ID of the given workspace from which we want to extract all reports.

    #Url for relevant query to run. 
    #Please note that some API calls require additional parameters - e.g. "admin/groups?`$top=50"
    $apiUri = "groups/$workspaceId/reports"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $file + "Power BI - Get Reports in Group.csv"
Write-Output "Writing results to $fileName..."

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

#Format results in tabular format.
$result | Export-Csv $fileName