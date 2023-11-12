# Plex Media Server update script
Are you running Plex Media Server on Windows Server as a Service? Do you have trouble updating with the built-in updater?
This script can help! It will download and install the latest available version from Plex's repository while managing the Windows Service.

**Don't forget to configure Plex's location and Service name variables at the first 2 lines of the script**:
```ps1
$PLEX_SERVICE = "Plex Media Server" #The name of the service that is running Plex Media Server
$PLEX_PATH = "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe" #The path to the Plex Media Server executable
```
After this, nothing should be changed unless necessary. Happy updating :)
