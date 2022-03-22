#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#Last updated: 3/22/2022.

#This script imports multiple files from a local RDL folder to a premium-capacity backed Power BI workspace.
#Before running, change the following parameters towards the end of the script: $groupId, $datasetsFilenames.
#Once the script is run, a pop-up window will open requesting the user to log in using a Power BI admin account.
#If authenticated correctly, the script will run.

#The script will list out each file that was successfully uploaded.
#If any files fail to upload, the script will list these out separately.
#Please see the attached link for potential reasons why a file could not be uploaded to the workspace:
#https://docs.microsoft.com/en-us/power-bi/paginated-reports/paginated-reports-faq#what-paginated-report-features-in-ssrs-aren-t-yet-supported-in-power-bi-

#Function to publish RDL file; do not change.
function Publish-ImportRDLFile 
{
    param
    (
        [string]$RdlFilePath,
        [string]$GroupId,
        [string]$nameConflict = "Abort"
    )

    # Get file content and create body
    $fileName = [IO.Path]::GetFileName($RdlFilePath)
    $boundary = [guid]::NewGuid().ToString()
    $fileBody = Get-Content -Path $RdlFilePath -Encoding UTF8 

    $body = @"
---------FormBoundary$boundary
Content-Disposition: form-data; name="$filename"; filename="$filename"
Content-Type: application/rdl

$fileBody 
---------FormBoundary$boundary--

"@

    # Get AccessToken and set it as header.
    $headers = Get-PowerBIAccessToken

    if ($GroupId) {
        $url = "https://api.powerbi.com/v1.0/myorg/groups/$GroupId/imports?datasetDisplayName=$fileName&nameConflict=$nameConflict"
    }
    else {
        $url = "https://api.powerbi.com/v1.0/myorg/imports?datasetDisplayName=$fileName&nameConflict=$nameConflict"
    }

    # Create import
    $report = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $body -ContentType "multipart/form-data"   
    $report.id
}

# Connect to Power BI.
Connect-PowerBIServiceAccount

#Premium capacity workspace where .RDL files will be uploaded.
#Parameter needs to be changed based on workspace to be written to.
$groupId = "59ef6793-2fe1-49ba-9603-fe3391c6dea6"

#Parent folder where files are currently stored.
#Parameter needs to be changed based on where files are stored locally.
$datasetsFilenames = Get-ChildItem "C:\Paginated Report Samples\"

#Loop to run through all files in the folder, loading each to the Power BI premium workspace.
foreach ($item in $datasetsFilenames) {
    try {
        Publish-ImportRDLFile -GroupId $groupId -RdlFilePath $item
        Write-Host "$item was uploaded."
    }
    catch [Exception] {
    $ErrorMessage = $_.Exception.Message
    Write-Host "$item could not be uploaded. This is likely because the report already exists in the workspace, or because the report contains an unsupported data source or feature."
    Write-Host "Please go to https://docs.microsoft.com/en-us/power-bi/guidance/migrate-ssrs-reports-to-power-bi#migration-tool for more information."
    }
    }