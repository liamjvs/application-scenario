<#
.SYNOPSIS
.DESCRIPTION
.PARAMETER Alias
.EXAMPLE
#>

Param (
    [string]$user,
    [string]$password,
    [string]$sqlserver
)

function Disable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force -ErrorAction SilentlyContinue
    Write-Host "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}
function Enable-InternetExplorerESC {
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 1 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 1 -Force
    Stop-Process -Name Explorer -ErrorAction SilentlyContinue
    Write-Host "IE Enhanced Security Configuration (ESC) has been enabled." -ForegroundColor Green
}
function Disable-UserAccessControl {
    Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "ConsentPromptBehaviorAdmin" -Value 00000000 -Force -ErrorAction SilentlyContinue
    Write-Host "User Access Control (UAC) has been disabled." -ForegroundColor Green    
}
Disable-UserAccessControl
Disable-InternetExplorerESC

# firewall
netsh advfirewall firewall add rule name="http" dir=in action=allow protocol=TCP localport=80

# folders
New-Item -ItemType Directory c:\temp -ErrorAction SilentlyContinue
New-Item -ItemType Directory c:\music -ErrorAction SilentlyContinue

# install iis
Install-WindowsFeature web-server -IncludeManagementTools

#install Visual C++
Invoke-WebRequest https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x64.exe -OutFile c:\temp\visualcplusplus.exe 
Start-Process c:\temp\visualcplusplus.exe -ArgumentList '/quiet' -Wait

# install dot.net core sdk
Invoke-WebRequest https://download.visualstudio.microsoft.com/download/pr/c6b9a396-5e7a-4b91-86f6-f9e8df3bf1dd/6d61addfd6069e404981bede03f8f4f9/dotnet-dev-win-x64.1.1.14.exe -outfile c:\temp\dotnet-dev-win-x64.1.1.14.exe
Start-Process c:\temp\dotnet-dev-win-x64.1.1.14.exe -ArgumentList '/quiet' -Wait
Invoke-WebRequest https://go.microsoft.com/fwlink/?LinkId=817246 -outfile c:\temp\DotNetCore.WindowsHosting.exe
Start-Process c:\temp\DotNetCore.WindowsHosting.exe -ArgumentList '/quiet' -Wait

# download / config music app
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest https://github.com/neilpeterson/nepeters-azure-templates/raw/master/dotnet-core-music-vm-sql-db/music-app/music-store-azure-demo-pub.zip -OutFile c:\temp\musicstore.zip
Expand-Archive C:\temp\musicstore.zip c:\music -Force
(Get-Content C:\music\config.json) | ForEach-Object { $_ -replace "<replaceserver>", $sqlserver } | Set-Content C:\music\config.json
(Get-Content C:\music\config.json) | ForEach-Object { $_ -replace "<replaceuser>", $user } | Set-Content C:\music\config.json
(Get-Content C:\music\config.json) | ForEach-Object { $_ -replace "<replacepass>", $password } | Set-Content C:\music\config.json

# workaround for db creation bug
Start-Process 'C:\Program Files\dotnet\dotnet.exe' -ArgumentList 'c:\music\MusicStore.dll'

#configure iis
Remove-WebSite -Name "Default Web Site"
Set-ItemProperty IIS:\AppPools\DefaultAppPool\ managedRuntimeVersion ""
New-Website -Name "MusicStore" -Port 80 -PhysicalPath C:\music\ -ApplicationPool DefaultAppPool -Force
& iisreset