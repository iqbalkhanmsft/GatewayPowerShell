#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/datasets/get-refresh-history-in-group

#DESCRIPTION: Get refresh history for a singular dataset in a given workspace.

    ####### PARAMETERS START #######

    $ClientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $ClientSecret = "VSa8Q~eLK11PlUPrroKRc_VCK5NHtORqUvy5CbY8"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"

    $WorkspaceId = "584d719d-4643-4604-ad18-cf93a39f8b53"
    $DatasetId = "8ea6f78f-54d8-4757-b902-5d94d4f917fb"

    $ApiUri = "groups/$WorkspaceId/datasets/$DatasetId/refreshes"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Connect to Power BI using manual authentication.
#Connect-PowerBIServiceAccount

#Execute REST API method.
$results = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get | ConvertFrom-Json

#Only store value of API return.
$resultsValue = $results.value

#Show results in a table format.
$resultsValue | Format-Table

#Run if any issues.
#Resolve-PowerBIError -Last