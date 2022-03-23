#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/directoryaudit-list?view=graph-rest-1.0&tabs=http

#DESCRIPTION: Returns all "update user" licensing logs from 2 days prior and before.

    ####### PARAMETERS START #######

    $clientID = "9d241b3d-fb86-41a0-a00d-9bee7b9fd855"
    $clientSecret = "Hnc7Q~fqK_E9.m9PV79__U2jA3UoWYhfTSygH"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Users\iqbalkhan.NORTHAMERICA\OneDrive - Microsoft\AHS Data\Graph API Licensing Logs - Historical.json" #Change based on where the file should be saved.

    $DaysToExtract = (Get-date).AddDays(-2).ToString("yyyy-MM-dd")
    Write-Output $DaysToExtract

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
#$apiUri = "https://graph.microsoft.com/beta/auditLogs/directoryAudits?`$filter=activityDisplayName eq `'Update user`' and activityDateTime le $DaysToExtract"
$apiUri = "https://graph.microsoft.com/beta/auditLogs/directoryAudits?`$expand=additionalDetails"

#Execute primary function using Uri and token generated above.
$results = RunQueryandEnumerateResults -apiUri $apiuri -token $token-

$results

#Save results to Csv. Change as needed.
#$results | Export-Csv $file -NoTypeInformation -Encoding utf8