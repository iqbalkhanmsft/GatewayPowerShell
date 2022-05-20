#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http

#DESCRIPTION: Returns a list of Azure AD groups filtered by display name; each group member is parsed into a unique record.

#WARNING: CODE IS FILTERED AND PARSED SPECIFICALLY FOR AHS SOLUTION.

    ####### PARAMETERS START #######

    $clientID = "6d35ae38-1d3a-4170-ab18-02652735f6bd" #Aka app ID.
    $clientSecret = "ys08Q~G54kwzI7ebricobXyPmufax9pot7SLyaGV"
    $tenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $file = "C:\Temp\" #Change based on where the file should be saved.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Set up file name for saving.
$fileName = $file + "Azure AD - Get Groups Export.csv"
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

#Continue to generate results even if pagination occurs.
function RunQueryandEnumerateResults {

    #Run Graph query.
    $results = (Invoke-RestMethod -Headers @{Authorization = "Bearer $($token)" } -Uri $apiUri -Method Get)

    #Begin populating results.
    $resultsValue = $results.value

    #If there is a next page, query the next page until there are no more pages left; append results to existing set.
    if ($results."@odata.nextLink" -ne $null) {
        $nextPageUri = $results."@odata.nextLink"
        #While there is a next page, query it and loop - append the results.
        while ($nextPageUri -ne $null) {
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
$apiUri = "https://graph.microsoft.com/v1.0/groups?`$filter=startswith(displayName, 'M365') OR startswith(displayName, 'Office_')&`$select=id,deletedDateTime,createdDateTime,description,displayName&`$expand=members($`select=userPrincipalName)"

#Execute primary function using Uri and token generated above.
$output = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#Create object to store parsed group data to.
$groups = @()

#For each group record, create custom object with parsed group members data.
foreach($item in $output)
{
    #Create custom object.
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name groupId ''
    $object | Add-Member -MemberType NoteProperty -Name deletedDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name createdDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name groupDescription ''
    $object | Add-Member -MemberType NoteProperty -Name groupDisplayName ''
    $object | Add-Member -MemberType NoteProperty -Name memberUPN ''

    #Insert values into object.
    $object.groupId = $item.id
    $object.deletedDateTime = $item.deletedDateTime
    $object.createdDateTime = $item.createdDateTime
    $object.groupDescription = $item.description #Renamed for clarity.
    $object.groupDisplayName = $item.displayName #Renamed for clarity.
    $object.memberUPN = ($item | select -ExpandProperty members).userPrincipalName #Grabs all values if multiple.

    #Append object to array.
    $groups += $Object

}

#Create object to store parsed group data to.
$export = @()

#For each group record, create custom object with parsed data.
foreach ($record in $filterGroups)
{
    foreach ($user in $record.memberUPN.split(','))
    {
        $export += [PSCustomObject]@{ 
            'groupId' = $record.groupId;
            'deletedDateTime' = $record.deletedDateTime;
            'createdDateTime' = $record.createdDateTime;
            'groupDescription' = $record.groupDescription
            'groupDisplayName' = $record.groupDisplayName  
            'memberUPN' = $user  
        }
    }
}

$export | Export-Csv $fileName