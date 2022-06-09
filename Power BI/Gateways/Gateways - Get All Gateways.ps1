#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://docs.microsoft.com/en-us/rest/api/power-bi/gateways/get-gateways

#DESCRIPTION: Extracts all gateways that the executing user is an admin of.
#Recommend adding the executing service principal's Azure AD security group as an admin to each gateway, so that all gateways' info are returned.

    ####### PARAMETERS START #######

    $ClientID = "53401d7d-b450-4f49-a888-0e0f1fabc1cf" #Aka app ID.
    $ClientSecret = "dih8Q~J.MvNuTB5PLUwuYcJOFzQuLmhMKOemZdkE"
    $TenantID = "96751c9d-db78-47f2-adff-d5876f878839"
    $File = "C:\Temp\" #Change based on where the file should be saved.

     ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Setup file name for saving.
$FileName = $File + "Power BI - Get All Gateways.csv"
Write-Output "Writing results to $FileName..."

#Create credential object using environment parameters.
$Password = ConvertTo-SecureString $ClientSecret -AsPlainText -Force
$Credential = New-Object PSCredential $ClientID, $Password

#Connect to Power BI with credentials of service principal.
Connect-PowerBIServiceAccount -ServicePrincipal -Credential $Credential -Tenant $TenantID -Environment USGov

#Connect to Power BI with credentials of a Power BI admin.
#Connect-PowerBIServiceAccount -Environment USGov

#Execute gateway API to return all gateways that the executing user is an admin of.
$APIResult = Invoke-PowerBIRestMethod -Url "gateways" -Method Get

#Store API response's value component only.
$APIValue = ($APIResult | ConvertFrom-Json).'value'

#Create object to store gateway data to.
$GatewaysObject = @()

#For each gateway object, parse out underlying gateway info that is currently stored in an array.
#For each gateway...
ForEach($GatewayItem in $APIValue) {

    #Create a custom object to store values within.
    $Object = New-Object PSObject
    $Object | Add-Member -MemberType NoteProperty -Name gatewayId ''
    $Object | Add-Member -MemberType NoteProperty -Name gatewayName ''
    $Object | Add-Member -MemberType NoteProperty -Name gatewayType ''
    #$Object | Add-Member -MemberType NoteProperty -Name gatewayContactInfo ''
    $Object | Add-Member -MemberType NoteProperty -Name gatewayVersion ''
    $Object | Add-Member -MemberType NoteProperty -Name gatewayMachine ''

    #Store API response values within object.
    $Object.gatewayId = $GatewayItem.id
    $Object.gatewayName = $GatewayItem.name
    $Object.gatewayType = $GatewayItem.type
    #$Object.gatewayContactInfo = ($GatewayItem | select -ExpandProperty gatewayAnnotation | ConvertFrom-Json).gatewayContactInformation
    $Object.gatewayVersion = ($GatewayItem | select -ExpandProperty gatewayAnnotation | ConvertFrom-Json).gatewayVersion
    $Object.gatewayMachine = ($GatewayItem | select -ExpandProperty gatewayAnnotation | ConvertFrom-Json).gatewayMachine

    #Add object to array.
    $GatewaysObject += $Object
   
}

#Store data to file.
$GatewaysObject | Export-Csv $FileName