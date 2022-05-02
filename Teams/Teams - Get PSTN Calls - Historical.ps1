#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/callrecords-callrecord-getpstncalls?view=graph-rest-1.0&tabs=http

#DESCRIPTION: #Script returns all PSTN data from the maximum 90 days out through the last completed day aka yesterday.

    ####### PARAMETERS START #######

    $clientID = "9e853f15-e2fd-4c0a-8d05-42ae6db840df" #Aka app ID.
    $clientSecret = "O8z8Q~~z2gQrUbszn6pSKjAU35zeZYheq9_0haWx"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\" #Change based on where the file should be saved to.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Set range of dates to be extracted.
$fromDate = (Get-date).AddDays(-90).ToString("yyyy-MM-dd") #Maximum # of days out that the script can return data - 90 days.
$toDate = (Get-date).AddDays(-2).ToString("yyyy-MM-dd") #Yesterday's date; the last completed date of call logs.

Write-Host "Exporting data from $fromDate to $toDate..."

$fileName = $file + "Historical - Teams PSTN Data Export.csv" #Complete file directory of data export.

Write-Host "Generating file named $fileName..."

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
$apiUri = "https://graph.microsoft.com/v1.0/communications/callRecords/getPstnCalls(fromDateTime=$fromDate,toDateTime=$toDate)"

#Execute primary function using Uri and token generated above.
$results = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#Save results to CSV.
$results | Export-Csv $fileName -NoTypeInformation -Encoding utf8