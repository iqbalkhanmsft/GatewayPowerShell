#For Clorox POC, git stuff added. Git added. Try again.

$AppId = "cde24cf1-620a-4d1f-82ee-44b2138e8002"
$Secret = "zBG7Q~MYyle3PtGzDazYJ0lGqPgb0.4RNN7mS"

#Can use app ID and secret.
Connect-DataGatewayServiceAccount -ApplicationId $AppId -ClientSecret $Secret

$Primary = Get-DataGatewayCluster
#Get-DataGatewayClusterStatus -GatewayClusterId 1da235ff-5d0f-41a4-945c-062e07ca307e

$Members =
ForEach ($cluster in $Primary)
    {

        Write-Host $Name
        ForEach ($member in (Get-DataGatewayClusterStatus -GatewayClusterId $cluster.Id))

        {

            [pscustomobject]@{

                PrimaryId = $cluster.Id
                PrimaryName = $cluster.Name
                PrimaryDescription = $cluster.Description
                PrimaryType = $cluster.Type
                MemberStatus = $member.ClusterStatus
                MemberVersion = $member.GatewayVersion
                MemberUpgradeState = $member.GatewayUpgradeState
                #Need to figure out how to convert list to string in order to get error message.
                #MemberErrorMessages = $member.MemberGatewayErrorMessages



            }


        }
    }

$Dir = "C:\Temp\GatewayStatusExport.csv"

#$Members | Where-Object {$Members.MemberStatus -like 'None'}

#Change to Live if wanting to show gateways that are active.
$Members | Where-Object {$Members.MemberStatus -like 'None'} | Export-Csv $Dir -NoTypeInformation -Encoding utf8

#Disconnect-DataGatewayServiceAccount