## Send basic email message via PowerShell.

#Documentation links and resources:
#SMTP server option: http://woshub.com/send-mailmessage-sending-emails-powershell/
#Walkthrough: https://adamtheautomator.com/send-mailmessage/
#MSFT: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/send-mailmessage?view=powershell-7.2

Start-Process -FilePath 'C:\Program Files\Google\Chrome\Application\chrome.exe'

$Message = "Hello! This is a test email sent via PowerShell." #Body of email.
$Subject = "Test email!" #Subject of email.
#smtp.gmail.com
#smtp-mail.outlook.com
#smtp.office365.com
$Server = "smtp-mail.outlook.com" #SMTP server to process your emails through. See SMTP documentation above for alternatives.
$From = "admin@powerbidawgs.com" #Email sender.
$To = "iqbalkhan9@gmail.com" #Email receiver. Add additional emails in 'X, Y, Z' format if sending to multiple recipients.
$Password = "iK124420!@"

#Install-Module -Name ExchangeOnlineManagement
Import-Module -Name ExchangeOnlineManagement
Connect-ExchangeOnline
Set-CASMailbox -Identity $From -SmtpClientAuthenticationDisabled $true

#Need to insert password for email sender here.
$SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force

#Create a new PSCredential using the username and secure string password.
$Credential = New-Object System.Management.Automation.PSCredential ($From, $SecurePassword)

Send-MailMessage -From $From -To $To -Subject $Subject -Body $Message -SmtpServer $Server -Credential $Credential -Port 587 -UseSsl