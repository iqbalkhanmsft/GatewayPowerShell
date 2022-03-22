#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.

#Script used to import multiple files from a local RDL folder to a Power BI workspace.
#Before running, change the following parameters at the bottom of the script: $groupId, 

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

$groupId = "59ef6793-2fe1-49ba-9603-fe3391c6dea6"

$datasetsFilenames = Get-ChildItem "C:\Paginated Report Samples\"

foreach ($item in $datasetsFilenames) {
    try {
        Publish-ImportRDLFile -GroupId $groupId -RdlFilePath $item
        Write-Host "Report $item was uploaded."
    }
    catch [Exception] {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Report $item could not be uploaded. This is likely because the report already exists in the workspace, or because the report contains an unsupported data source or feature."
    Write-Host "Please go to https://docs.microsoft.com/en-us/power-bi/guidance/migrate-ssrs-reports-to-power-bi#migration-tool for more information."
    }
    }


# Create Import
#$id = Publish-ImportRDLFile -GroupId $groupId -RdlFilePath "C:\Paginated Report Samples\Sales Order.rdl"
# Set password
#Set-BasicPassword-To-RDL -Id $id -GroupId $groupId -UserName "user1@powerbidawgs.onmicrosoft.com" -Password "iK525356!@"