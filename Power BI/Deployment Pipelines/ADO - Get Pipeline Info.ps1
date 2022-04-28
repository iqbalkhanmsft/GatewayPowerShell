#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/pipelines/get-pipeline-operations

#DESCRIPTION: Authenticate to the Power BI tenant using login via service principal.
#Executes Power BI deployment pipeline REST APIs to return info.

    ####### PARAMETERS START #######

    $clientID = "f25b1f83-ef28-4395-aa55-8347fe9e282d" #Aka app ID.
    $clientSecret = "pwi8Q~gRF5_q0NZ1_rXd6tEQq6btAvBS.UR0Iasd"
    $tenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $file = "C:\Temp\" #Change based on where the file should be saved.
    $pipelineid = "65f0c564-dbcf-4572-b703-2c606f855cc5"

    #Url for relevant query to run.
    $apiUri = "reports"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$fileName = $file + "Power BI - Get Pipeline Info Example.csv"
Write-Output "Writing results to $fileName..."

#Create credential object using environment parameters.
#$Password = ConvertTo-SecureString $clientSecret -AsPlainText -Force
#$Credential = New-Object PSCredential $clientID, $password

#Connect to Power BI with credentials of Service Principal.
Connect-PowerBIServiceAccount #-ServicePrincipal -Credential $Credential -Tenant $TenantID

#Not needed, since Connect-PowerBIServiceAccount provides authentication necessary for executing Power BI REST APIs.
#Get-PowerBIAccessToken -AsString

#Execute rest method.
$result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get | ConvertFrom-Json | select -ExpandProperty value

#Format results in tabular format.
$result #| Export-Csv $fileName