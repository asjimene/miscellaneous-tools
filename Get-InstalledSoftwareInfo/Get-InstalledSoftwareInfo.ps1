$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName,DisplayVersion,Version,UninstallString,QuietUninstallString
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName,DisplayVersion,Version,UninstallString,QuietUninstallString
$Clipboard = $Apps | Sort-Object DisplayName | Out-Gridview -Title "Select Application" -OutputMode Single | select -First 1
($Clipboard | Out-String).TrimStart().TrimEnd() | Set-Clipboard