$DetectionScript = @'
$AppName = "@AppName" # DisplayName in Add/Remove Programs
$AppVersion = "@AppVersion" # DisplayVersion of the App in Add/Remove Programs
$WindowsInstaller = @WindowsInstaller # 1 or 0 | 1 is MSI 0 is EXE
$SystemComponent = @SystemComponent # 1 or 0 | 1 is SystemComponent = 1, 0 is SystemComponent does not exist or is 0

# Gather all the apps in the Add/Remove Programs Registry Keys
$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller, SystemComponent
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller, SystemComponent

# Check is the App DisplayName is found and the version in the registry is greater than or equal to the specified AppVersion
$AppFound = $Apps | Where-Object {
	($_.DisplayName -like $AppName) -and ([version]$_.DisplayVersion -ge [version]$AppVersion) -and ([bool]$_.WindowsInstaller -eq [bool]$WindowsInstaller) -and ([bool]$_.SystemComponent -eq [bool]$SystemComponent)
}

# Post some output if the app is found
if ($AppFound) {
	Write-Output "Installed"
}
'@

$Apps = ((Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | Select-Object DisplayName, DisplayVersion, Version, WindowsInstaller, SystemComponent, UninstallString, QuietUninstallString, Publisher, URLInfoAbout, InstallLocation, InstallSource, PSPath) | Where-object {-not([System.String]::IsNullOrEmpty($_.DisplayName))}
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | Select-Object DisplayName, DisplayVersion, SystemComponent, WindowsInstaller, Version, UninstallString, QuietUninstallString, Publisher, URLInfoAbout, InstallLocation, InstallSource, PSPath | Where-object { -not([System.String]::IsNullOrEmpty($_.DisplayName)) }
$SelectedApp = $Apps | Sort-Object DisplayName | Out-GridView -Title "Select Application" -OutputMode Single | Select-Object -First 1
$WindowsInstaller = if ([bool]$SelectedApp.WindowsInstaller){1}else{0}
$SystemComponent = if([bool]$SelectedApp.SystemComponent){1}else{0}
$SelectedApp.DisplayName -match '(?:(\d+)\.)?(?:(\d+)\.)?(?:(\d+)\.\d+)'
if ($Matches){
	$version = $Matches[0]
	$DisplayNameNew = ($SelectedApp.DisplayName).Replace($version, '*')
} else {
	$DisplayNameNew = $SelectedApp.DisplayName
}

$DetectionScript = $DetectionScript.Replace("@AppName", $DisplayNameNew).Replace("@AppVersion", $SelectedApp.DisplayVersion).Replace("@WindowsInstaller", $WindowsInstaller).Replace("@SystemComponent", $SystemComponent)
$DetectionScript | Out-File -FilePath "$PSScriptRoot\$($DisplayNameNew.Replace('*','').Replace('  ',' ')).ps1" -Encoding oem -Force