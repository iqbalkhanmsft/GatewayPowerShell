#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/directoryaudit-list?view=graph-rest-1.0&tabs=http

#DESCRIPTION: Returns all "update user" licensing logs from 2 days prior and before.

    ####### PARAMETERS START #######

    $clientID = "0c5c2d4d-ffe7-43bf-9ad3-38a4e534f0a4" #Aka app ID.
    $clientSecret = "2Fb7Q~W12hFTaF5gMngd5XIP~yrxoluXLd9xp"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\" #Change based on where the file should be saved.

    $date = (((Get-Date).Date).AddDays(-1)) #Get yesterday's date.
    $extractEndpoint = (Get-Date -Date (($Date).AddMilliseconds(-1)) -Format yyyy-MM-ddTHH:mm:ssZ) #Subtract one second from the start of yesterday.
    Write-Output "Extracting data from $extractEndpoint and prior..."
    
    $fileName = $file + "Graph API Licensing Logs - Historical.json" #Change based on where the file should be saved.
    Write-Output "Writing results to $fileName..."

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
#$apiUri = "https://graph.microsoft.com/beta/auditLogs/directoryAudits?`$filter=activityDisplayName eq `'Update user`' and activityDateTime le $extractEndpoint"
$apiUri = "https://graph.microsoft.com/beta/auditLogs/directoryAudits?`$filter=activityDateTime le $extractEndpoint"

#Execute primary function using Uri and token generated above.
$results = RunQueryandEnumerateResults -apiUri $apiuri -token $token

#Create object to store relevant logs to.
$licenseChange = @()

#For each log, store data in object if display name is like AssignedLicense.
foreach($item in $results)
{
    if ($item | select -ExpandProperty targetresources | select -ExpandProperty modifiedProperties | where{$_.displayName -like "AssignedLicense"})
    {
    $licenseChange += $item
    }
}

#Create object to store formatted license data to.
$auditReport = @()

#For each license log, create custom object with appropriate data.
foreach($changedObject in $licenseChange)
{
    #Create custom object.
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name Category ''
    $object | Add-Member -MemberType NoteProperty -Name ActivityDisplayName ''
    $object | Add-Member -MemberType NoteProperty -Name OperationType ''
    $object | Add-Member -MemberType NoteProperty -Name ActivityDateTime ''
    $object | Add-Member -MemberType NoteProperty -Name ActivityResult ''
    $object | Add-Member -MemberType NoteProperty -Name TargetUser ''
    $object | Add-Member -MemberType NoteProperty -Name InitiatedBy ''
    $object | Add-Member -MemberType NoteProperty -Name OldLicenseSKU ''
    $object | Add-Member -MemberType NoteProperty -Name NewLicenseSKU ''

    #1:1 assignments.
    $object.Category = $changedObject.category
    $object.ActivityDisplayName = $changedObject.activityDisplayName
    $object.OperationType = $changedObject.operationType
    $object.ActivityDateTime = $changedObject.activityDateTime
    $object.ActivityResult = $changedObject.result

    #Target user.
    $object.TargetUser = ($changedObject | select -ExpandProperty targetResources).userPrincipalName

    #Initiated by.
    $object.InitiatedBy = ($changedObject.initiatedBy | select -ExpandProperty user).userPrincipalName

    #Store modified license data for use below.
    $modifiedData = ($changedObject | select -ExpandProperty targetResources).modifiedProperties #Store modified properties.
    $assignedLicense  = $ModifiedData | where{$_.displayname -like 'AssignedLicense'} #Only keep license-related modified properties.

    #Identify old SKUs.
    [string]$OSKU = @()
    if($assignedLicense.oldValue -eq '[]') #If oldValue is null, then no old SKU.
        {$Object.OldLicenseSKU -eq $Null}
    else
        {
            $OSKUNames = $assignedLicense.oldvalue.Split('["[,[]]"')  | where{$_ -like '*Skuname*'}
            if(($OSKUNames | Measure-Object).Count -ge "1"){$OSKUNames | ForEach-Object{$OSKU += $_; $OSKU += ";"}}
            else{$Object.NewLicenseSKU = $OSKUNames  -replace ('SkuName=')}
            $Object.OldLicenseSKU = $OSKU -replace ('SkuName=')
        }
    
    #Identify new SKUs.
    [string]$NSKU = @()
    if($assignedLicense.newValue -eq '[]') #If newValue is null, then no new SKU.
        {$Object.NewLicenseSKU -eq $Null}
    else
        {
            $NSKUNames = $assignedLicense.newvalue.Split('["[,[]]"')  | where{$_ -like '*Skuname*'}
            if(($NSKUNames | Measure-Object).Count -ge "1"){$NSKUNames | ForEach-Object{$NSKU += $_; $NSKU += ";"}}
            else{$Object.NewLicenseSKU = $NSKUNames  -replace ('SkuName=')}
            $Object.NewLicenseSKU = $NSKU -replace ('SkuName=')
        }

    $auditReport += $Object

}

$auditReport #| ConvertTo-Json | Out-File $fileName