#Change to directory where the RDL application was downloaded to.
#Need to have this at the exact subfolder where the .exe file is located.
cd C:\Users\iqbalkhan.NORTHAMERICA\Downloads\RdlMigration\bin\Release

#Sample code: # RdlMigration <your Base url endpoint> <file Path> <WorkspaceName> <client-id>

#Change report server name if not running locally.
#Can change file path to individual report, Sharepoint folder, etc.
#Client ID comes from app registration.
#Will likely need to authenticate to pop-up window using Admin account.

#Keep directory to under 260 characters long.
.\RdlMigration.exe  http://DESKTOP-D1DFU65:80/ReportServer "C:\Paginated Report Samples" a8e21833-72ae-4eed-9821-c067a8cbc2c8