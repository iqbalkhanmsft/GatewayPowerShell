#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/graph/api/resources/user?view=graph-rest-1.0#properties

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.
#Does not work, since Power BI REST APIs require being logged in.

    ####### PARAMETERS START #######

    $clientID = "db2c307a-be4f-46bf-894a-f148653df596" #Aka app ID.
    $clientSecret = "2ff7Q~fk_pCZXmd5YgO~sZAaXr4udJvQ8B-yP"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\" #Change based on where the file should be saved.
    $apiUri = "admin/capacities" #Url for relevant query to run. Please note that some API calls require additional parameters - e.g. "admin/groups?`$top=50"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $file + "Power BI - Auth Token Output.csv" #Change based on where the file should be saved to.
Write-Output "Writing results to $fileName..."

#Generate PBI token using app registration credentials.
function GetPBIToken {
    
    #Construct URI.
    $uri = "https://login.windows.net/$tenantID/oauth2/token"
         
    #Construct body.
    $body = @{
        resource = "https://analysis.windows.net/powerbi/api"
        client_id     = $clientId
        grant_type    = "client_credentials"
        client_secret = $clientSecret
        
    }
         
    #Get OAuth 2.0 token.
    $tokenRequest = Invoke-WebRequest -Method Post -Uri $uri -ContentType "application/x-www-form-urlencoded" -Body $body -UseBasicParsing
         
    #Generate access token.
    $token = ($tokenRequest.Content | ConvertFrom-Json).access_token

}

Invoke-PowerBIRestMethod -Headers @{Authorization = "Bearer $($token)" } -Url "reports" -Method Get