if ($env:PROCESSOR_ARCHITECTURE -eq 'x86' -and $env:PROCESSOR_ARCHITEW6432 -eq 'ARM64') {
    $PowerShellPath = "$env:windir\SysNative\WindowsPowerShell\v1.0\powershell.exe"    
    $CommandLineArgs = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID").CommandLine -replace '^.+?powershell\.exe"?\s?'
    $Process = Start-Process -FilePath $PowerShellPath -ArgumentList $CommandLineArgs -NoNewWindow -Wait -PassThru
    exit $Process.ExitCode
}

$AppName = "" # DisplayName in Add/Remove Programs
$AppVersion = "" # DisplayVersion of the App in Add/Remove Programs
$WindowsInstaller =  # 1 or 0 | 1 is MSI 0 is EXE
$SystemComponent =  # 1 or 0 | 1 is SystemComponent = 1, 0 is SystemComponent does not exist or is 0
$binaryToCheck = # Path to an executable to check if an application is ARM or Intel x64 (leave $null to skip check)
$binaryToCheckResult = # Expected result for the binaryToCheck set to one of the following (leave at $null to skip check): AMD64 (x64),ARM64,x86 (I386)

function Get-PeMachineType {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }

    # Open the file in binary mode
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        # 1. From the DOS header, read e_lfanew (offset to PE header) at 0x3C
        [byte[]]$buffer = New-Object byte[] 4
        $fs.Seek(0x3C, 'Begin') | Out-Null
        $fs.Read($buffer, 0, 4) | Out-Null
        $peOffset = [BitConverter]::ToInt32($buffer, 0)

        # 2. Move to the PE header and check the "PE\0\0" signature
        $fs.Seek($peOffset, 'Begin') | Out-Null
        $fs.Read($buffer, 0, 4) | Out-Null
        # "PE\0\0" => 0x50 0x45 0x00 0x00
        if ($buffer[0] -ne 0x50 -or
            $buffer[1] -ne 0x45 -or
            $buffer[2] -ne 0x00 -or
            $buffer[3] -ne 0x00) {
            return "Not a valid PE file (missing 'PE\0\0' signature)."
        }

        # 3. Immediately after the "PE\0\0" signature is the COFF header
        #    The first 2 bytes of the COFF header = Machine field
        [byte[]]$machineBytes = New-Object byte[] 2
        $fs.Read($machineBytes, 0, 2) | Out-Null
        $machine = [BitConverter]::ToUInt16($machineBytes, 0)

        # 4. Interpret the Machine field
        switch ($machine) {
            0x8664 { return "AMD64 (x64)" }
            0x14C  { return "x86 (I386)" }
            0xAA64 { return "ARM64" }
            0x1C0  { return "ARM (32-bit)" }
            default { return "Unknown or unsupported machine: 0x{0:X4}" -f $machine }
        }
    }
    finally {
        $fs.Close()
    }
}

# Gather all the apps in the Add/Remove Programs Registry Keys
$Apps = (Get-ChildItem HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller, SystemComponent
$Apps += (Get-ChildItem HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\) | Get-ItemProperty | select DisplayName, DisplayVersion, WindowsInstaller, SystemComponent

# Check is the App DisplayName is found and the version in the registry is greater than or equal to the specified AppVersion
$AppFound = $Apps | Where-Object {
	($_.DisplayName -like $AppName) -and ([version]$_.DisplayVersion -ge [version]$AppVersion) -and ([bool]$_.WindowsInstaller -eq [bool]$WindowsInstaller) -and ([bool]$_.SystemComponent -eq [bool]$SystemComponent)
}

if ($null -ne $binaryToCheck){
	$binaryCheckResult = Get-PeMachineType -Path $binaryToCheck
	if (-not ($AppFound -and $binaryCheckResult -eq $binaryToCheckResult)) {
		$AppFound = $null
	}
}

# Post some output if the app is found
if ($AppFound) {
	Write-Output "$AppName Detected"
}