 #Dependencies
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$webClient = new-object System.Net.WebClient
$TempPath = "C:\Temp"

#Write-Output "Adjust performance options in registry"
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2   

#Disable Hyper-V Video
$url = "https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0/file/147248/2/DeviceManagement.zip"
$DeviceManagement = "DeviceManagement.zip"
$DeviceManagement_folder = "DeviceManagement"
Write-Output "Downloading Device Management Powershell Script from $url"
$webClient.DownloadFile($url, "$TempPath\$DeviceManagement")
Unblock-File -Path "$TempPath\$DeviceManagement"
Write-Output "Extracting Device Management Powershell Script"
Expand-Archive "$TempPath\$DeviceManagement" -DestinationPath "$TempPath\$DeviceManagement_folder" -Force
Write-Output "Disabling Hyper-V Video"
Import-Module "$TempPath\$DeviceManagement_folder\DeviceManagement.psd1"
Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false

#Disable-TCC
$nvsmi = "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
$gpu = & $nvsmi --format=csv,noheader --query-gpu=pci.bus_id
& $nvsmi -g $gpu -fdm 0

schtasks.exe /delete /f /tn HeadlessRestartTask

Restart-Computer