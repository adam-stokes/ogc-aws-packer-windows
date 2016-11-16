$ProgressPreference = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'

Set-MpPreference -DisableRealtimeMonitoring $true

$services = @(
	"diagnosticshub.standardcollector.service"
	"DiagTrack"
	"dmwappushservice"
	"lfsvc"
	"MapsBroker"
	"NetTcpPortSharing"
	"RemoteAccess"
	"RemoteRegistry"
	"SharedAccess"
	"TrkWks"
	"WbioSrvc"
	"XblAuthManager"
	"XblGameSave"
)
foreach ($service in $services) {
	Get-Service -Name $service | Set-Service -StartupType Disabled
}

Disable-PSRemoting
Get-Service -Name "WinRM" | Set-Service -StartupType Disabled

reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server" /v fDenyTSConnections /t REG_DWORD /d 1 /f

Invoke-Webrequest "https://github.com/git-for-windows/git/releases/download/v2.7.2.windows.1/Git-2.7.2-64-bit.exe" -OutFile git.exe -UseBasicParsing
Start-Process git.exe -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /CLOSEAPPLICATIONS /DIR=c:\git\' -Wait
Remove-Item -Force git.exe
setx /M PATH "$Env:Path;c:\git\cmd"

Add-Type -AssemblyName System.Web
$lc = Get-Content C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json -raw | ConvertFrom-Json
$lc.AdminPasswordType = "Specify"
$lc.AdminPassword = "test12#test12#"
$lc | ConvertTo-Json | set-content C:\ProgramData\Amazon\EC2-Windows\Launch\Config\LaunchConfig.json

Add-Content $Env:ProgramData\Amazon\EC2-Windows\Launch\Sysprep\BeforeSysprep.cmd 'del "C:\Program Files\OpenSSH-Win64\*_key*"'
Add-Content $Env:ProgramData\Amazon\EC2-Windows\Launch\Sysprep\BeforeSysprep.cmd 'del C:\Users\Administrator\.ssh\authorized_keys'
Add-Content $Env:ProgramData\Amazon\EC2-Windows\Launch\Sysprep\BeforeSysprep.cmd 'del C:\provision.ps1'

$scriptcommand = 'powershell -ExecutionPolicy Bypass -NoProfile -c "& C:\specialize-script.ps1 -password ''{0}''"' -f $lc.AdminPassword
Add-Content $Env:ProgramData\Amazon\EC2-Windows\Launch\Sysprep\SysprepSpecialize.cmd $scriptcommand

& $Env:ProgramData\Amazon\EC2-Windows\Launch\Scripts\InitializeInstance.ps1 -Schedule
& $Env:ProgramData\Amazon\EC2-Windows\Launch\Scripts\SysprepInstance.ps1
