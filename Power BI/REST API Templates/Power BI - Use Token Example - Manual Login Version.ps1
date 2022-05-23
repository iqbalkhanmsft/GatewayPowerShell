#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/invoke-powerbirestmethod?view=powerbi-ps

#DESCRIPTION: Authenticate to the Power BI tenant using manual login.

    ####### PARAMETERS START #######

    #Url for relevant query to run. Please note that some API calls require additional parameters - e.g. "admin/groups?`$top=50"
    $apiUri = "groups/0be252fd-f744-4d90-b1ce-b06c0a2a5f6b/reports"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $file + "Power BI - All Capacities.csv"
Write-Output "Writing results to $fileName..."

#Connect to Power BI with credentials of authorized user.
Connect-PowerBIServiceAccount

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

#Format results in tabular format.
$result | Export-Csv $fileName