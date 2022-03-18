$AppName = "" # DisplayName in Add/Remove Programs
$AppVersion = "" # DisplayVersion of the App in Add/Remove Programs
$WindowsInstaller= "" # 1 or 0 | 1 is MSI 0 is EXE

# Gather all the apps in the Add/Remove Programs Registry Keys
$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller

# Check is the App DisplayName is found and the version in the registry is greater than or equal to the specified AppVersion
$AppFound = $Apps | Where-Object {
	($_.DisplayName -like $AppName) -and ([version]$_.DisplayVersion -ge [version]$AppVersion) -and ($_.WindowsInstaller -eq $WindowsInstaller)
}

# Post some output if the app is found
if ($AppFound) {
	Write-Output "Installed"
}