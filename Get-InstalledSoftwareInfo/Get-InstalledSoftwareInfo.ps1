#requires -Version 2
function Out-Notepad
{
	#Function provided by: https://community.idera.com/database-tools/powershell/powertips/b/tips/posts/send-text-to-notepad
	param
	(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[String][AllowEmptyString()]
		$Text
	)
	
	begin
	{
		$sb = New-Object System.Text.StringBuilder
	}
	
	process
	{
		$null = $sb.AppendLine($Text)
	}
	end
	{
		$text = $sb.ToString()
		
		$process = Start-Process notepad -PassThru
		$null = $process.WaitForInputIdle()
		
		
		$sig = '
      [DllImport("user32.dll", EntryPoint = "FindWindowEx")]public static extern IntPtr FindWindowEx(IntPtr hwndParent, IntPtr hwndChildAfter, string lpszClass, string lpszWindow);
      [DllImport("User32.dll")]public static extern int SendMessage(IntPtr hWnd, int uMsg, int wParam, string lParam);
    '
		
		$type = Add-Type -MemberDefinition $sig -Name APISendMessage -PassThru
		$hwnd = $process.MainWindowHandle
		[IntPtr]$child = $type::FindWindowEx($hwnd, [IntPtr]::Zero, "Edit", $null)
		$null = $type::SendMessage($child, 0x000C, 0, $text)
	}
}


$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, Version, UninstallString, QuietUninstallString, Publisher, URLInfoAbout, InstallLocation, InstallSource, PSPath
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, Version, UninstallString, QuietUninstallString, Publisher, URLInfoAbout, InstallLocation, InstallSource, PSPath
$Clipboard = $Apps | Sort-Object DisplayName | Out-Gridview -Title "Select Application" -OutputMode Single | select -First 1
($Clipboard | Out-String -Width 1000).TrimStart().TrimEnd() | Set-Clipboard
($Clipboard | Out-String -Width 1000).TrimStart().TrimEnd()| Out-Notepad
