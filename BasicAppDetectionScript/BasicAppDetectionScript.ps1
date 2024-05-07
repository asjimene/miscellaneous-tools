$AppName = "" # DisplayName in Add/Remove Programs
$AppVersion = "" # DisplayVersion of the App in Add/Remove Programs
$WindowsInstaller =  # 1 or 0 | 1 is MSI 0 is EXE
$SystemComponent =  # 1 or 0 | 1 is SystemComponent = 1, 0 is SystemComponent does not exist or is 0

# Gather all the apps in the Add/Remove Programs Registry Keys
$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller, SystemComponent
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller, SystemComponent

# Check is the App DisplayName is found and the version in the registry is greater than or equal to the specified AppVersion
$AppFound = $Apps | Where-Object {
	($_.DisplayName -like $AppName) -and ([version]$_.DisplayVersion -ge [version]$AppVersion) -and ([bool]$_.WindowsInstaller -eq [bool]$WindowsInstaller) -and ([bool]$_.SystemComponent -eq [bool]$SystemComponent)
}

# Post some output if the app is found
if ($AppFound) {
	Write-Output "Installed $AppName"
}