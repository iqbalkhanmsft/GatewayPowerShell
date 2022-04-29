#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.profile/invoke-powerbirestmethod?view=powerbi-ps

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.

    ####### PARAMETERS START #######

    $clientID = "INSERT HERE" #Aka app ID.
    $clientSecret = "INSERT HERE"
    $tenantID = "INSERT HERE"
    $file = "C:\Temp\" #Change based on where the file should be saved.

    #Url for relevant query to run. Please note that some API calls require additional parameters - e.g. "admin/groups?`$top=50"
    $apiUri = "admin/capacities"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $file + "Power BI - All Capacities.csv"
Write-Output "Writing results to $fileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $clientID, $password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Not needed, since Connect-PowerBIServiceAccount provides authentication necessary for executing Power BI REST APIs.
#Get-PowerBIAccessToken -AsString

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

#Format results in tabular format.
$result | Export-Csv $fileName