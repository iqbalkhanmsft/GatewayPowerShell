#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-group-users-as-admin

#DESCRIPTION: Extract all workspaces and underlying users via REST API and service principal.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "Oem8Q~Vr8ebpcuiFwilfjeSPCMoNqhDtaoIYxbfS"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    $Top = 5000 #Number of workspaces to return; max = 5000.

    #Url for relevant query to run.
    $ApiUri = "admin/groups?`$top=$Top"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspaces + Users (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $apiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

#Create object to store workspace and parsed user info to.
$WorkspacesObject = @()

#Since a workspace may have multiple users, split users out into individual records.
#For each workspace...
ForEach($Item in $ResultValue) {

    #Store workspace ID for use in workspace API below.
    $workspaceId = $Item.id

    #Execute workspace API for the given workspace ID in the loop.
    #API returns each underlying user as an individual record so that no parsing is required.
    $APIResult = Invoke-PowerBIRestMethod -Url "admin/groups/$workspaceId/users" -Method Get

    #Store API response's value component only.
    $APIValue = ($APIResult | ConvertFrom-Json).'value'

    #Add workspace info to API response.
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceId' -Value $Item.id
    $APIValue | Add-Member -MemberType NoteProperty -Name 'isOnDedicatedCapacity' -Value $Item.isOnDedicatedCapacity
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceType' -Value $Item.type
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceState' -Value $Item.state
    $APIValue | Add-Member -MemberType NoteProperty -Name 'workspaceName' -Value $Item.name

    #Add object to array.
    $WorkspacesObject += $APIValue

}

#Format results in tabular format.
$WorkspacesObject | Export-Csv $FileName