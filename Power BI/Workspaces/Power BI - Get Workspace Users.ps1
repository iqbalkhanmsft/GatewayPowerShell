#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoftpowerbimgmt.reports/get-powerbireport?view=powerbi-ps

#DESCRIPTION: Extract all Power BI workspace users by role.

    ####### PARAMETERS START #######

    $ClientID = "f9f34dda-95cc-4cd6-9984-ea90eff20de3" #Aka app ID.
    $ClientSecret = "MMI8Q~6NQ8jrgNxEVsUj83R6Pfxec1DdynO8PdlH"
    $TenantID = "84fb42a1-8f75-4c94-9ea6-0124b5a276c5"
    $File = "C:\Temp\" #Change based on where the file should be saved.
    
     ####### PARAMETERS END #######
    
    ####### BEGIN SCRIPT #######
    
    #Setup file name for saving.
    $FileName = $File + "Power BI - All Workspace Users.csv"
    Write-Output "Writing results to $FileName..."
    
    #Create credential object using environment parameters.
    $Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
    $Credential = New-Object PSCredential $ClientID, $Password
    
    #Connect to Power BI with credentials of Service Principal.
    Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID

    #Connect to Power BI using a Power BI admin account + OAuth.
    #Commented out in place of Service Principal login above.
    #Connect-PowerBIServiceAccount
    
    #Get all workspaces.
    $WorkspaceUsers = Get-PowerBIWorkspace -Scope Organization  | 
    
    #For each workspace name and ID, get user identifier and access type; export to file.
    ForEach-Object {
    $WorkspaceName = $_.Name
    $WorkspaceId = $_.Id
    $WorkspaceDescription = $_.Description
    $UsingCapacity = $_.IsOnDedicatedCapacity
    $CapacityID = $_.CapacityId
    $WorkspaceState = $_.State
    $WorkspaceType = $_.Type
    ForEach ($User in $_.Users) {
    [PSCustomObject]@{
    WorkspaceName = $WorkspaceName
    WorkspaceId = $WorkspaceId
    WorkspaceDescription = $WorkspaceDescription
    UsingCapacity = $UsingCapacity
    CapacityID = $CapacityID
    WorkspaceState = $WorkspaceState
    WorkspaceType = $WorkspaceType
    User = $User.Accessright    
    Identifier = $User.Identifier
    PrincipalType = $User.PrincipalType
    UserPrincipalName = $User.UserPrincipalName}
    }
    }
    
    #Export data to file.
    $WorkspaceUsers | Export-CSV $FileName -NoTypeInformation