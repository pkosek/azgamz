param (
    $admin_username,
    $admin_password
 ) 
 
#Dependencies
[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$webClient = new-object System.Net.WebClient
$TempPath = "C:\Temp"   
mkdir $TempPath
 
#Format DataDisk
Get-Disk | Where-Object partitionstyle -eq 'raw' | ` 
Initialize-Disk -PartitionStyle GPT -PassThru | ` 
New-Partition -DriveLetter S -UseMaximumSize | ` 
Format-Volume -FileSystem NTFS -NewFileSystemLabel "STEAM" -Confirm:$false

#Disable-InternetExplorerESC
$AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
$UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
Stop-Process -Name Explorer -Force

#Write-Output "Disable unnecessary scheduled tasks"
Disable-ScheduledTask -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag'
Disable-ScheduledTask -TaskName 'ProactiveScan' -TaskPath '\Microsoft\Windows\Chkdsk'
Disable-ScheduledTask -TaskName 'Scheduled' -TaskPath '\Microsoft\Windows\Diagnosis'
Disable-ScheduledTask -TaskName 'SilentCleanup' -TaskPath '\Microsoft\Windows\DiskCleanup'
Disable-ScheduledTask -TaskName 'WinSAT' -TaskPath '\Microsoft\Windows\Maintenance'
Disable-ScheduledTask -TaskName 'Windows Defender Cache Maintenance' -TaskPath '\Microsoft\Windows\Windows Defender'
Disable-ScheduledTask -TaskName 'Windows Defender Cleanup' -TaskPath '\Microsoft\Windows\Windows Defender'
Disable-ScheduledTask -TaskName 'Windows Defender Scheduled Scan' -TaskPath '\Microsoft\Windows\Windows Defender'
Disable-ScheduledTask -TaskName 'Windows Defender Verification' -TaskPath '\Microsoft\Windows\Windows Defender'
Disable-ScheduledTask -TaskName 'ServerManager' -TaskPath '\Microsoft\Windows\Server Manager' 

#Install nVidia Driver - https://docs.microsoft.com/en-us/azure/virtual-machines/windows/n-series-driver-setup
#latest driver can be found here but may not be supported by Azure: https://www.nvidia.co.uk/Download/driverResults.aspx/158350/en-uk
$url = "https://go.microsoft.com/fwlink/?linkid=874181"
$driver_file = "grid_win10_64bit_international_whql.exe"
Write-Output "Downloading Nvidia M60 driver from URL $url"
$webClient.DownloadFile($url, "$TempPath\$driver_file")
Write-Output "Installing Nvidia M60 driver from file $TempPath\$driver_file"
Start-Process -FilePath "$TempPath\$driver_file" -ArgumentList "-s", "-noreboot" -Wait
 
#Enable-Audio
Write-Output "Enabling Audio Service"
Set-Service -Name "Audiosrv" -StartupType Automatic
Start-Service Audiosrv
 
#Set up Audio
$compressed_file = "VBCABLE_Driver_Pack43.zip"
$driver_folder = "VBCABLE_Driver_Pack43"
$driver_inf = "vbMmeCable64_win7.inf"
$hardward_id = "VBAudioVACWDM"
Write-Output "Downloading Virtual Audio Driver"
$webClient.DownloadFile("http://vbaudio.jcedeveloppement.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "$TempPath\$compressed_file")
Unblock-File -Path "$TempPath\$compressed_file"
Write-Output "Extracting Virtual Audio Driver"
Expand-Archive "$TempPath\$compressed_file" -DestinationPath "$TempPath\$driver_folder" -Force
$wdk_installer = "wdksetup.exe"
$devcon = "C:\Program Files (x86)\Windows Kits\10\Tools\x64\devcon.exe"
Write-Output "Downloading Windows Development Kit installer"
$webClient.DownloadFile("http://go.microsoft.com/fwlink/p/?LinkId=526733", "$TempPath\$wdk_installer")
Write-Output "Downloading and installing Windows Development Kit"
Start-Process -FilePath "$TempPath\$wdk_installer" -ArgumentList "/S" -Wait
$cert = "vb_cert.cer"
$url = "https://github.com/ecalder6/azure-gaming/raw/master/$cert"
Write-Output "Downloading vb certificate from $url"
$webClient.DownloadFile($url, "$TempPath\$cert")
Write-Output "Importing vb certificate"
Import-Certificate -FilePath "$TempPath\$cert" -CertStoreLocation "cert:\LocalMachine\TrustedPublisher"
Write-Output "Installing virtual audio driver"
Start-Process -FilePath $devcon -ArgumentList "install", "$TempPath\$driver_folder\$driver_inf", $hardward_id -Wait

#Install Choco
Write-Output "Installing Chocolatey"
Invoke-Expression ($webClient.DownloadString('https://chocolatey.org/install.ps1'))
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
chocolatey feature enable -n allowGlobalConfirmation

#Disable IPv6
Set-Net6to4Configuration -State disabled
Set-NetTeredoConfiguration -Type disabled
Set-NetIsatapConfiguration -State disabled

#Install-Steam
choco install steam --y --installargs "/S /D=S:\Steam"

# Add-DisconnectShortcut
$WshShell = New-Object -comObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\disconnect.lnk") 
$Shortcut.TargetPath = "C:\Windows\System32\tscon.exe"
$Shortcut.Arguments = "1 /dest:console"
$Shortcut.Save()

# Add-AutoLogin 
Write-Output "Make the password and account of admin user never expire."
Set-LocalUser -Name $admin_username -PasswordNeverExpires $true -AccountNeverExpires

Write-Output "Make the admin login at startup."
$registry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Set-ItemProperty $registry "AutoAdminLogon" -Value "1" -type String
Set-ItemProperty $registry "DefaultDomainName" -Value "$env:computername" -type String
Set-ItemProperty $registry "DefaultUsername" -Value $admin_username -type String
Set-ItemProperty $registry "DefaultPassword" -Value $admin_password -type String

#This downloads and schedules the next script
$webClient.DownloadFile("https://raw.githubusercontent.com/pkosek/azgamz/master/2_setupScript.ps1", "$TempPath\2_setupScript.ps1")
schtasks.exe /create /f /tn HeadlessRestartTask /ru SYSTEM /sc ONSTART /tr "powershell.exe -file $TempPath\2_setupScript.ps1"

Restart-Computer