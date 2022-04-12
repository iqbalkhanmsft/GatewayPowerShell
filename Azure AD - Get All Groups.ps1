#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/group-list?view=graph-rest-1.0&tabs=http

#DESCRIPTION: Returns all Azure AD groups.

    ####### PARAMETERS START #######

    $clientID = "0c5c2d4d-ffe7-43bf-9ad3-38a4e534f0a4" #Aka app ID.
    $clientSecret = "2Fb7Q~W12hFTaF5gMngd5XIP~yrxoluXLd9xp"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\AHS - Get Groups Export.json" #Change based on where the file should be saved to.

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
$apiUri = "https://graph.microsoft.com/v1.0/groups?`$select=id,deletedDateTime,assignedLicenses,createdDateTime,description,displayName&`$expand=members"

#Execute primary function using Uri and token generated above.
$output = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#Create object to store formatted license data to.
$groups = @()

#For each license log, create custom object with appropriate data.
foreach($item in $output)
{
    #Create custom object.
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name groupId ''
    $object | Add-Member -MemberType NoteProperty -Name deletedDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name createdDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name groupDescription ''
    $object | Add-Member -MemberType NoteProperty -Name groupDisplayName ''
    $object | Add-Member -MemberType NoteProperty -Name assignedLicensesAll '' #Used as an intermediary.
    $object | Add-Member -MemberType NoteProperty -Name assignedLicenses ''
    $object | Add-Member -MemberType NoteProperty -Name memberDisplayNameAll '' #Used as an intermediary.
    $object | Add-Member -MemberType NoteProperty -Name memberDisplayName ''
    $object | Add-Member -MemberType NoteProperty -Name memberUPNAll '' #Used as an intermediary.
    $object | Add-Member -MemberType NoteProperty -Name memberUPN ''

    #Insert values into object.
    $object.groupId = $item.id
    $object.deletedDateTime = $item.deletedDateTime
    $object.createdDateTime = $item.createdDateTime
    $object.groupDescription = $item.description #Renamed for clarity.
    $object.groupDisplayName = $item.displayName #Renamed for clarity.
    $object.assignedLicensesAll = ($item | select -ExpandProperty assignedLicenses).skuID #Grabs all values if multiple.
    $object.memberDisplayNameAll = ($item | select -ExpandProperty members).displayName #Grabs all values if multiple.
    $object.memberUPNAll = ($item | select -ExpandProperty members).userPrincipalName #Grabs all values if multiple.

    #AssignedLicenses.
    #Format multiple member display names into list.*
    if($object.assignedLicensesAll -eq $Null) #If value is null, leave as null.
        {$object.assignedLicenses -eq $Null}
    if(($object.assignedLicensesAll | Measure-Object).Count -gt "1")
        {$object.assignedLicensesAll | ForEach-Object{$object.assignedLicenses += $_; $object.assignedLicenses += ";"}} #Create list concatenated by ;.
    if(($object.assignedLicensesAll | Measure-Object).Count -eq "1")
        {$object.assignedLicenses = $object.assignedLicensesAll}

    $object.assignedLicenses = $object.assignedLicenses.trimEnd(';') #Trim trailing semi-colons.

    #MemberDisplayName.
    #Format multiple member display names into list.*
    if($object.memberDisplayNameAll -eq $Null) #If value is null, leave as null.
        {$object.memberDisplayName -eq $Null}
    if(($object.memberDisplayNameAll | Measure-Object).Count -gt "1")
        {$object.memberDisplayNameAll | ForEach-Object{$object.memberDisplayName += $_; $object.memberDisplayName += ";"}} #Create list concatenated by ;.
    if(($object.memberDisplayNameAll | Measure-Object).Count -eq "1")
        {$object.memberDisplayName = $object.memberDisplayNameAll}

    $object.memberDisplayName = $object.memberDisplayName.trimEnd(';') #Trim trailing semi-colons.

    #MemberUPN.
    #Format multiple member display names into list.*
    if($object.memberUPNAll -eq $Null) #If value is null, leave as null.
        {$object.memberUPN -eq $Null}
    if(($object.memberUPNAll | Measure-Object).Count -gt "1")
        {$object.memberUPNAll | ForEach-Object{$object.memberUPN += $_; $object.memberUPN += ";"}} #Create list concatenated by ;.
    if(($object.memberUPNAll | Measure-Object).Count -eq "1")
        {$object.memberUPN = $object.memberUPNAll}

    $object.memberUPN = $object.memberUPN.trimEnd(';') #Trim trailing semi-colons.

    #Append object to array.
    $groups += $Object

}

$groups | Select-Object groupId, deletedDateTime, createdDateTime, groupDescription, groupDisplayName, assignedLicenses,
memberDisplayName, memberUPN | ConvertTo-Json | Out-File $file