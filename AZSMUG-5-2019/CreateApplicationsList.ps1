$Site = "ASU:"
$LogFile = "C:\Temp\UpdateImagingFiles.log"

if ((Get-Item $LogFile -ErrorAction SilentlyContinue).Length -gt 500000) {
	Write-Output "----------- $(Get-Date -Format G) -----------" > $LogFile
}
else {
	Write-Output "----------- $(Get-Date -Format G) -----------" >> $LogFile
}

## Import Configuration Manager and Save Current Location
Import-Module ConfigurationManager -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
Import-Module (Join-Path $(Split-Path $env:SMS_ADMIN_UI_PATH) ConfigurationManager.psd1) -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

# Update All Available Applications List
Write-Output "----------- $(Get-Date -Format G) Gathering All Applications List -----------" >> $LogFile
Write-Output "----------- $(Get-Date -Format G) ScriptRoot = $PSScriptRoot -----------" >> $LogFile
Push-Location
Set-Location $Site
$ApplicationsList = Get-CMApplication -Fast | Where-Object -Property NumberOfDeploymentTypes -ge 1 | Where-Object -Property LocalizedCategoryInstanceNames -Contains "Ready" | Where-Object -property IsExpired -eq $false | Select-Object LocalizedDisplayName, SoftwareVersion
Pop-Location
Write-Host $ApplicationsList

if (-not ([System.String]::IsNullOrEmpty($ApplicationsList[0]))) {
    Write-Output "$(Get-Date -Format G) - Exporting Application CSV" >> $LogFile
    $ApplicationsList | Export-Csv -Path "$PSScriptRoot\ApplicationsList.csv" -NoTypeInformation -Force
} else {
    Write-Output "$(Get-Date -Format G) - No Applications found in list, not exporting" >> $LogFile
}
