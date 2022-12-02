#This tool is intended to identify and cleanup entries in the Windows Registry keys that contain Add/Remove Programs information. The script loops through the HKLM\SOFTWARE\[WOW6432Node]\Microsoft\Windows\CurrentVersion\Uninstall Registry keys, checks to see if there is a maching product code in HKEY_CLASSES-ROOT\Installers\Products. If a key does not exist in HKCR, the script can remediate by deleting the entry from ARP.
#This script is still a work-in-progress, please test it exstensively before use!
#I am not responsible for any damage caused by this tool!

Function Convert-GUIDtoPID {
	[CmdletBinding()]
	param(
		#Accepts only GUID data type, to ensure Valid string format.
		[Parameter(Mandatory = $True, ValueFromPipeline = $true, Position = 0)]
		[GUID]$GUID
	)

	#Stripping off the brackets and the dashes from the GUID, leaving only alphanumerical chars.
	$ProductIDChars = [regex]::replace($GUID, "[^a-zA-Z0-9]", "")

	#1. Reversing the first 8 characters, next 4, next 4. Then for the latter half, reverse every two char.
	$RearrangedCharIndex = 7, 6, 5, 4, 3, 2, 1, 0, 11, 10, 9, 8, 15, 14, 13, 12, 17, 16, 19, 18, 21, 20, 23, 22, 25, 24, 27, 26, 29, 28, 31, 30
	Return -join ($RearrangedCharIndex | ForEach-Object { $ProductIDChars[$_] })
}

# Set this to $true to clean up entries
$Remediate = $false
$MSIInstalls = Get-ChildItem HKLM:\SOFTWARE\Microsoft\WIndows\Currentversion\uninstall | Where-Object { $_.PSChildName -as [guid] -is [guid] -and ((Get-ItemProperty $_.PSPath).WindowsInstaller -eq 1) }
if (Test-Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\WIndows\Currentversion\uninstall") {
	$MSIInstalls += Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\WIndows\Currentversion\uninstall | Where-Object { $_.PSChildName -as [guid] -is [guid] -and ((Get-ItemProperty $_.PSPath).WindowsInstaller -eq 1) }
}

if (-not (Test-Path "HKCR:\SOFTWARE" -ErrorAction SilentlyContinue)) {
	New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
} 

foreach ($MSI in $MSIInstalls) {
	$RegPID = Convert-GUIDtoPID -GUID $MSI.PSChildName
	if (-not (Test-Path "HKCR:\Installer\Products\$RegPID" -ErrorAction SilentlyContinue)) {
		Write-Output "MSI not installed for $((Get-ItemProperty ($MSI.PSPath)).DisplayName)"
		Write-Output "$(Get-Date -Format o) - MSI not installed for $((Get-ItemProperty ($MSI.PSPath)).DisplayName)" >> $env:TEMP\MSIInstallFileCheck.log
		if ($Remediate -eq $true) {
			if (Test-Path $MSI.PSPath -ErrorAction SilentlyContinue) {
				Write-Output "Remediation Enabled, Deleting ARP Registry Entry for $((Get-ItemProperty ($MSI.PSPath)).DisplayName)"
				Write-Output "$(Get-Date -Format o) - Remediation Enabled, Deleting ARP Registry Entry for $((Get-ItemProperty ($MSI.PSPath)).DisplayName)" >> $env:TEMP\MSIInstallFileCheck.log
				Remove-Item $MSI.PSPath -ErrorAction SilentlyContinue
			}
		}
		else {
			Write-Output "Remediation NOT Enabled, Keeping ARP Registry Entry for $((Get-ItemProperty ($MSI.PSPath)).DisplayName)"
		}
	}
}