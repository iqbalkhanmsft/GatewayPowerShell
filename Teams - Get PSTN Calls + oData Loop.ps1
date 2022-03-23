#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/callrecords-callrecord-getpstncalls?view=graph-rest-1.0&tabs=http

#DESCRIPTION: Authenticates to Azure AD using token generated via app registration credentials.
#Script returns all PSTN data from the maximum 90 days out through the day prior.

####### PARAMETERS START #######

$clientID = "5f259238-f085-4f48-9bcc-0c4678dce3df"
$clientSecret = "kE67Q~nBQpdH2U0rR95vpTKoux2b2fLhJNGGO"
$tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
$file = "C:\Temp\BCBS - Teams PSTN Data Export.csv" #Change based on where the file should be saved.

$fromDate = (Get-date).AddDays(-90).ToString("yyyy-MM-dd") #Maximum # of days our the script can return data - 90 days.
$toDate = (Get-date).AddDays(-1).ToString("yyyy-MM-dd") #Through yesterday.

####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Generate Graph API token using app registration credentials.
function GetGraphToken {
    
    #Construct URI.
    $uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
         
    #Construct body.
    $body = @{
        client_id     = $clientId
        scope         = "https://graph.microsoft.com/.default"
        client_secret = $clientSecret
        grant_type    = "client_credentials"
    }
         
    #Get OAuth 2.0 token.
    $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
         
    #Generate access token.
    $token = ($tokenRequest.Content | ConvertFrom-Json).access_token
    return $token

}

#Continue to generate results even if pagination exists.
function RunQueryandEnumerateResults {

    #Run Graph Query.
    $results = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)" } -Uri $apiUri -Method Get)

    #Begin populating results.
    $resultsValue = $results.value

    #If there is a next page, query the next page until there are no more pages and append results to existing set.
    if ($results."@odata.nextLink" -ne $null) {
        write-host enumerating pages -ForegroundColor yellow
        $nextPageUri = $results."@odata.nextLink"
        #While there is a next page, query it and loop - append the results.
        While ($nextPageUri -ne $null) {
            $nextPageRequest = (Invoke-RestMethod -Headers @{authorization = "Bearer $($token)" } -Uri $nextPageURI -Method Get)
            $nxtPageData = $nextPageRequest.Value
            $nextPageUri = $nextPageRequest."@odata.nextLink"
            $resultsValue = $resultsValue + $nxtPageData
        }
    }

    #Return the completed results.
    return $resultsValue

}

#Execute GetGraphToken function using relevant parameters.
$token = GetGraphToken -ClientSecret $clientSecret -ClientID $clientID -TenantID $tenantID

#Uri for relevant query to run.
#Pulled out assignedLicenses, assignedPlans, licenseAssignmentStates, provsionedPlans for now.
$apiUri = "https://graph.microsoft.com/v1.0/communications/callRecords/getPstnCalls(fromDateTime=$fromDate,toDateTime=$toDate)"

#Execute primary function using Uri and token generated above.
$results = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#Save results to Csv. Change as needed.
$results | Export-Csv $file -NoTypeInformation -Encoding utf8