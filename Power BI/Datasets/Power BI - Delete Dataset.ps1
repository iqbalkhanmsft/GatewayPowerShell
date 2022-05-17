#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/delete-dataset-in-group

#DESCRIPTION: Authenticate to the Power BI tenant using workspace admin login.

#WARNING: CURRENTLY SET TO US GOV ENVIRONMENT.

    ####### PARAMETERS START #######
   
    $groupId = "f313b3e9-e502-415e-818d-93e6ac985b90"
    $datasetId = "69664ff5-20b2-4a90-815d-29afff1f33fd"

    #Url for relevant query to run.
    $apiUri = "groups/$groupId/datasets/$datasetId"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

Write-Output "Deleting dataset $datasetId..."

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -Environment USGov

#Execute rest method.
Invoke-PowerBIRestMethod -Url $apiUri -Method Delete

#Run if error thrown.
#Resolve-PowerBIError

#Format results in tabular format.
Write-Output "If no error thrown, dataset $datasetId has been deleted. Please check workspace $groupId to confirm deletion."