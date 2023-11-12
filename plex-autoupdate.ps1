$PLEX_SERVICE = "Plex Media Server" #The name of the service that is running Plex Media Server
$PLEX_PATH = "C:\Program Files\Plex\Plex Media Server\Plex Media Server.exe" #The path to the Plex Media Server executable
$PLEX_LATEST_VERSION_METADATA_LOCATION = "https://plex.tv/pms/downloads/5.json"
$PLEX_INSTALLER_LOG_FILE = "pms.log"
$PLEX_INSTALLER_PARAMS = "/verysilent /norestart /log `"$PLEX_INSTALLER_LOG_FILE`""

#The scripts requires admin permissions
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (!$currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Output "This script needs to stop the Plex service($PLEX_SERVICE). Please run as administrator."
    Read-Host -Prompt "Press Enter to exit"
    exit
}

$currentPlexVersion = (Get-Item $PLEX_PATH).VersionInfo.FileVersion
$windowsArch = (Get-CimInstance Win32_operatingsystem).OSArchitecture

Write-Output "Current Plex version is $currentPlexVersion"
Write-Output "Fetching latest available version..."
$plexVersionMetadata = Invoke-RestMethod -Uri $PLEX_LATEST_VERSION_METADATA_LOCATION
$windowsVersionMetadata = $plexVersionMetadata.computer.Windows
Write-Output "Latest available version is $($windowsVersionMetadata.version)"
Write-Output "New features:"
Write-Output $windowsVersionMetadata.items_added
Write-Output "Fixes:"
Write-Output $windowsVersionMetadata.items_fixed
Write-Output ""
$confirm = Read-Host "Update?(y/n)"
if ($confirm -ne 'y') {
    exit
}

$updateCandidate = $null
foreach ($release in $windowsVersionMetadata.releases) {
    if ($release.label -eq "Windows $windowsArch") {
        $updateCandidate = $release
        break
    }
}

if ($null -eq $updateCandidate) {
    Write-Error "Couldn't find any matching release for your OS architecture: $windowsArch"
    Read-Host
    exit
}

Write-Output "$($updateCandidate.label) has been chosen for the update according to your OS"
$confirm = Read-Host "Continue?(y/n)"
if ($confirm -ne 'y') {
    exit
}

try {
    Write-Output "Downloading update file..."
    $updateFile = "PMS-$($updateCandidate.build)-$($windowsVersionMetadata.version).exe"
    $client = New-Object net.webclient
    $client.Downloadfile($updateCandidate.url, $updateFile)
    
    Write-Output "Stopping service $PLEX_SERVICE..."
    Stop-Service -Name $PLEX_SERVICE
    (Get-Service $PLEX_SERVICE).WaitForStatus('Stopped')
    
    Write-Output "Updating Plex..."
    & "$(Resolve-Path $updateFile)" $PLEX_INSTALLER_PARAMS.Split(" ") | Out-Null
    
    Write-Output "Starting service $PLEX_SERVICE..."
    Start-Service -Name $PLEX_SERVICE
    (Get-Service $PLEX_SERVICE).WaitForStatus('Running')
    
    Write-Output "Deleting upate artifacts..."
    Remove-Item $updateFile
    Remove-Item $PLEX_INSTALLER_LOG_FILE
    
    Write-Output "All done :)"
}
catch {
    Write-Error "Something went south, won't delete artifacts so you can investigate"
}

Read-Host