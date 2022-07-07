#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-groups-as-admin
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/admin/groups-get-group-users-as-admin

#DESCRIPTION: Extract all active workspaces and underlying users via REST API and service principal or PBI admin credentials.

    ####### PARAMETERS START #######

    $ClientID = "c6f7cf55-9159-4e40-a0e0-57bd32ec3e41" #Aka app ID.
    $ClientSecret = "C-28Q~T~KB1F16Oktn3z_lS7TtetRz5Zie-TSbJF"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.

    $Top = 5000 #Number of workspaces to return; API's max = 5000.

    $Skip = 0 #Number of workspaces to skip during each batch.

    #Url for relevant query to run.
    $ApiUri = '/admin/groups?$top=5000&' + '$skip=' + $Skip + '&$filter=state eq' + " 'Active'"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - All Workspaces + Users (API).csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID #-Environment USGov

#Connect to Power BI with credentials of Power BI admin.
#Connect-PowerBIServiceAccount -Environment USGov

#Run PS script to get the total # of workspaces in the organization.
#Limited to workspaces that are active, as deleted workspaces cause 404 (not found) issues with the API.
$Result = Get-PowerBIWorkspace -Scope Organization -All | Where-Object {($_.State -eq "Active")}

#Save the total # of workspaces to be used later in the API loop.
$TotalWorkspaces = $Result.Count

#Execute the API once if the total # of active workspaces is less than or equal to 5000, which is the API limit.
If($TotalWorkspaces -le 5000){

#Execute REST API.
$Result = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get

#Store API response's value component only.
$ResultValue = ($Result | ConvertFrom-Json).'value'

}

#Execute the API multiple times if the total # of active workspaces is greater than 5000. 
ElseIf($TotalWorkspaces -gt 5000){

#Create array to store workspace values to as the loop executes.
$ResultValue = @()

#Loop parameters; add 5000 workspaces at a time to the skip parameter until the # of records queried is greater than or equal to the total # of workspaces.
#Starting at 0, execute the API in batches of 5000 at a time; skipping 5000 workspaces each time the script executes until the total # of workspaces returned has been exhausted.
    For($Skip = 0; $Skip + $Top -ge $TotalWorkspaces; $Skip + 5000){

    #Define API URI using the loop iterator.
    $ApiUri = '/admin/groups?$top=5000&' + '$skip=' + $Skip + '&$filter=state eq' + " 'Active'"

    #Execute REST API.
    $Result = Invoke-PowerBIRestMethod -Url $ApiUri -Method Get

    #Store API response's value component only.
    $Value = ($Result | ConvertFrom-Json).'value'

    #Add values to array.
    $ResultValue += $Value
        
    }

}

#Create object to store workspace and parsed user info to.
$WorkspacesObject = @()

#Since a workspace may have multiple users, split users out into individual records.
#For each workspace...
ForEach($Item in $ResultValue) {

    #Store workspace ID for use in workspace + users API below.
    $workspaceId = $Item.Id

    #Execute workspace + users API for the given workspace ID in the loop.
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