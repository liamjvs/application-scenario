# BeatUp-Windows.ps1
#

$psProcess = gps -id $PID
$psInstances = (gps -Name $psProcess.name).count
if ($psInstances -gt 1) {
$psName = "{0}#{1}" -f $psProcess.name,$($psInstances - 1)
}
else {
$psName = $psProcess.name
}

# RAM in box
#$box=get-WMIobject Win32_ComputerSystem
#$Global:physMB=$box.TotalPhysicalMemory / 1024 /1024
# So first task - let's now go soak up all available RAM
#####################
#$a = "a" * 256MB
#$growArray = @()
#$growArray += $a
# leave 512Mb for the OS to survive.
#$HEADROOM=512
#$bigArray = @()
#$ram = $physMB - $psPerfMEM.NextValue()
#$MAXRAM=$physMB - $HEADROOM
#$k=0
#while ($ram -lt $MAXRAM) {
#$bigArray += ,@($k,$growArray)
#$k += 1
#$growArray += $a
#$ram = $physMB - $psPerfMEM.NextValue()
#}
#####################
# and now release it all.
#$bigArray.clear()
#remove-variable bigArray
#$growArray.clear()
#remove-variable growArray
#[System.GC]::Collect()
#####################

#
# and now launch N powershell processes to saturate all CPUs.
#
$SCRIPT="foreach (`$n in 1..2147483647) {`$r=1; foreach (`$x in 1..2147483647) {`$r = `$r * `$x}; `$r }"
$si = new-object System.Diagnostics.ProcessStartInfo
$si.FileName = "PowerShell.EXE"
$si.Arguments = $SCRIPT

$cpus=$env:NUMBER_OF_PROCESSORS
for ($cpu = 0; $cpu -lt $cpus; $cpu++) {
$proc = [System.Diagnostics.Process]::Start($si)
}