function DynamicVariablesList {
	param (
		[String]$DefaultApps,
		[String]$ExtraApps,
		[String]$OfficePkgName
	)
	
	$SoftwareList = @()
	
	# Office Apps Processing
	if ($OfficePkgName -ne "None") {
		$SoftwareList += $OfficePkgName	
	}
	
	# Default Apps Processing
	foreach ($Application in $DefaultApps.Split(",")) {
		$AppToInstall = $Global:ApplicationsList | where -Property LocalizedDisplayName -Like $Application | sort -Property SoftwareVersion -Descending
		
		if ($AppToInstall -ne $null) {
			$SoftwareList = $SoftwareList + $($AppToInstall[0].LocalizedDisplayName)
		}
	}
	
	# Extra Apps Processing
	if ($ExtraApps -ne "None") {
		foreach ($Application in $ExtraApps.Split(",")) {
			if ($Application -eq "-") {
                # Clear all Default Apps and only install the "Extra" apps
				$SoftwareList = @()
				
                # Readd the office App if the list is cleared
				# Office Apps Processing
				If ($OfficePkgName -ne "None") {
					$SoftwareList += $OfficePkgName
				}
			}
            # Add the Extra App to the list of apps to install
			$AppToInstall = $Global:ApplicationsList | where -Property LocalizedDisplayName -Like $Application | sort -Property SoftwareVersion -Descending
			if ($AppToInstall -ne $null) {
				$SoftwareList = $SoftwareList + $($AppToInstall[0].LocalizedDisplayName)
			}
		}
	}
	
	$SoftwareList = $SoftwareList | select -Unique
	# Create Dynamic Variables List
	$Counter = 0
	foreach ($AppInstall in $SoftwareList) {
		$Counter = $Counter + 1
		$DeployVar = "$Global:DeploymentsVarName$($Counter.tostring("00"))"
		if (-not $Global:TestEnabled) {
			$TSEnvironment.Value("$DeployVar") = $AppInstall
			New-Variable -Name $DeployVar -Value $AppInstall -Scope Global
		}
		else {
			Write-Host "Creating: $DeployVar  Value: $AppInstall"	
		}
	}
}

# Toggle to False for usage in a task sequence
$Global:TestEnabled = $True

# Name of the Dynamic Application Variable
$Global:DeploymentsVarName = "SCCMDynAppInstall"

# Path to Applications List
$Global:ApplicationsList = Import-Csv "$PSScriptRoot\ApplicationsList.csv"

# Set the Applications to Install

#Base Apps are included on Every image
$BaseApps = "Microsoft CMTrace,Google Chrome *,Adobe Acrobat Reader DC 19.*,Adobe Flash Player NPAPI*,Mozilla Firefox Quantum ESR*,VLC Media Player*"

# Additional apps can be set per department etc, and will be installed on top of the Base Apps
$AdditionalApps = "7-Zip*,Citrix Receiver LTSR*"

# If Different Office versions are available, they can also be chosen
$OfficeApplication = "Microsoft Office Professional Plus 64-bit 2019"

DynamicVariablesList -DefaultApps $BaseApps -ExtraApps $AdditionalApps -OfficePkgName $OfficeApplication
