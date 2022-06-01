#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/serviceprincipal-list?view=graph-rest-1.0&tabs=http

#DESCRIPTION: #Script returns all service principals for the given Azure AD tenant.

#WARNING - MAY NEED TO CHANGE API FOR GOV; ALSO NEED TO ACCOUNT FOR LOOPS.

    ####### PARAMETERS START #######

    $clientID = "91d4c088-3bcf-46bb-89b0-9de5356c8e88" #Aka app ID.
    $clientSecret = "lXU8Q~PXtktsGZBFXEwt8TWgyb0hNS5YRKlb1ceY"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\" #Change based on where the file should be saved to.

    ####### PARAMETERS END #######
    
####### BEGIN SCRIPT #######

$fileName = $file + "Azure AD - All Service Principals.csv"

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

    #Return the completed results.
    return $resultsValue

}

#Execute GetGraphToken function using relevant parameters.
$token = GetGraphToken -ClientSecret $clientSecret -ClientID $clientID -TenantID $tenantID

#Uri for relevant query to run.
$apiUri = "https://graph.microsoft.com/v1.0/servicePrincipals"

#Execute primary function using Uri and token generated above.
$results = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#$results | Export-Csv $fileName -NoTypeInformation -Encoding utf8

#Save results to CSV, specifically those records for the given date.
$keys = $results | Select-Object -ExpandProperty keyCredentials

#Save results to CSV, specifically those records for the given date.
#$filteredkeys = $keys | Where-Object {$_.keyId -ne $null}

#Create object to store parsed group data to.
$expand = @()

#For each group record, create custom object with parsed group members data.
foreach($item in $keys)
{
    #Create custom object.
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name customKeyIdentifier ''
    $object | Add-Member -MemberType NoteProperty -Name displayName ''
    $object | Add-Member -MemberType NoteProperty -Name endDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name key ''
    $object | Add-Member -MemberType NoteProperty -Name keyId ''
    $object | Add-Member -MemberType NoteProperty -Name startDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name type ''
    $object | Add-Member -MemberType NoteProperty -Name usage ''

    #Insert values into object.
    $object.customKeyIdentifier = $item.customKeyIdentifier
    $object.displayName = $item.displayName
    $object.endDateTime = $item.endDateTime
    $object.key = $item.key
    $object.keyId = $item.keyId
    $object.startDateTime = $item.startDateTime
    $object.type = $item.type
    $object.usage = $item.usage

    #Append object to array.
    $expand += $object

}

$expand #| Export-Csv $fileName -NoTypeInformation -Encoding utf8