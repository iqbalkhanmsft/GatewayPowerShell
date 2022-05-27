#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/get-adminflow?view=pa-ps-latest
#DOCUMENTATION: https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/get-usersorgroupsfromgraph?view=pa-ps-latest

#DESCRIPTION: Extracts a list of all Power Automate artifacts for the given environment.
#User must be a Global Admin, Environment Admin, or Power Platform Admin to execute this script.

    ####### PARAMETERS START #######

    $File = "C:\Temp\" #Change based on where the file should be saved.

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Install Power Apps modules, uncomment as necessary.
#Install-Module -Name Microsoft.PowerApps.Administration.PowerShell
#Install-Module -Name Microsoft.PowerApps.PowerShell -AllowClobber

#Import Power Apps module.
Import-Module -Name Microsoft.PowerApps.Administration.PowerShell

#Setup file name for saving.
$FileName = $File + "Power Automate - All Flows.csv"
Write-Output "Writing results to $FileName..."

#Get all flows.
$flows = Get-AdminFlow 

#Create object to store parsed results to.
$artifacts = @()

#Loop through each flow.
foreach ($item in $flows)
{

    #For each artifact, return the user.
    $user = Get-UsersOrGroupsFromGraph -ObjectId $item.CreatedBy.userId

    #Create custom object.
    $object = New-Object PSObject
    $object | Add-Member -MemberType NoteProperty -Name resourceType ''
    $object | Add-Member -MemberType NoteProperty -Name displayName ''
    $object | Add-Member -MemberType NoteProperty -Name environmentName ''
    $object | Add-Member -MemberType NoteProperty -Name createdByEmail ''

    #Insert values into object.
    $object.resourceType = 'Power Automate'
    $object.displayName = $item.displayName
    $object.environmentName = $item.environmentName
    $object.createdByEmail = $user.description

    #Append object to array.
    $results += $Object

}

# output to file on given Path
$results #| Export-Csv -Path $Path