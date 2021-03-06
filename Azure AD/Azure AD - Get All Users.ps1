#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0#properties

#DESCRIPTION:
#Returns all users from Azure AD + underlying user information.

#REQUIREMENTS:
#Make sure to add User.Read.All permissions in Azure AD for the relevant app registration.

    ####### PARAMETERS START #######

    $clientID = "0c5c2d4d-ffe7-43bf-9ad3-38a4e534f0a4" #Aka app ID.
    $clientSecret = "9bq8Q~g5dL_NRfj4BShbY5UTjJjNvV3CGdTEac1S"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\" #Change based on where the file should be saved to.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $file + "Azure AD - Get Users Export.csv" #Change based on where the file should be saved to.
Write-Output "Writing results to $fileName..."

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

#Execute GetGraphToken function using the relevant parameters.
$token = GetGraphToken -ClientSecret $clientSecret -ClientID $clientID -TenantID $tenantID

#Uri for relevant query to run.
#Pulled out assignedLicenses, assignedPlans, licenseAssignmentStates, provsionedPlans for now.
$apiUri = "https://graph.microsoft.com/v1.0/users?`$select=accountEnabled,ageGroup,city,companyName,country,createdDateTime,creationType,deletedDateTime,department,displayName,employeeHireDate,employeeId,employeeType,givenName,id,jobTitle,mail,mailNickname,officeLocation,postalCode,state,streetAddress,surname,usageLocation,userPrincipalName,userType"

#Execute primary function using Uri and token generated above.
$results = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#Save results to Csv. Change as needed.
$results | Export-Csv $fileName -NoTypeInformation -Encoding utf8