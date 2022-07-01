#DISCLAIMER: Scripts should go through the proper testing and validation before being run in production.
#DOCUMENTATION: https://www.ubibot.com/platform-api/2735/get-channel-feed-summaries/

#DESCRIPTION: Extracts temperature logging data - for Henry Chen / MTA POC.

    ####### PARAMETERS START #######

    #API key for given channel.
    $ApiKey = "9df2b5019ae5d0b081f0d090839fa89d"

    #Channel ID.
    $ChannelId = 25036

    #Relevant API to be executed.
    $ApiUri = "https://api.ubibot.com/channels/$ChannelId/summary?api_key=$apiKey"

    #File directory where file should be saved.
    $Directory = "C:\Temp\" 

    #File name to be saved.
    $FileName = "Henry Chen - Temperature Logging Extract.json"

    ####### PARAMETERS END #######

####### BEGIN SCRIPT #######

#Create full directory and file name for export to be saved.
$File = $Directory + $FileName

#Execute REST API.
$Result = Invoke-RestMethod -Uri $apiUri -Method Get

$Result | ConvertTo-Json | Out-File $File
