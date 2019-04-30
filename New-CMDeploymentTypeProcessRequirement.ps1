Function New-CMDeploymentTypeProcessRequirement {
    # Creates a Deployment Type Process Requirement "Install Behavior tab in Deployment types" by copying an existing Process Requirement.
    # A Process requirement needs to be Defined in the "Install Behavior" Tab of the "SourceApplicationName" Variable before this script will function properly
	Param (
		[System.String]$SourceApplicationName,
		[System.String]$DestApplicationName,
		[System.String]$DestDeploymentTypeName,
        [System.String]$ProcessRequirementDisplayName,
        [System.String]$ProcessRequirementExecutable
	)
    Push-Location
    Set-Location $SCCMSite
	$DestDeploymentTypeIndex = 0
 
    # get the applications
    $SourceApplication = Get-CMApplication -Name $SourceApplicationName | ConvertTo-CMApplication
    $DestApplication = Get-CMApplication -Name $DestApplicationName | ConvertTo-CMApplication
	
	# Get DestDeploymentTypeIndex by finding the Title
	$DestApplication.DeploymentTypes | ForEach-Object {
		$i = 0
	} {
		If ($_.Title -eq "$DestDeploymentTypeName") {
			$DestDeploymentTypeIndex = $i
			
		}
		$i++
    }
    
    # Get requirement rules from source application
    $ProcessRequirementsList = $SourceApplication.DeploymentTypes[0].Installer.InstallProcessDetection.ProcessList[0]
    $ProcessRequirementsList
    if (-not ([System.String]::IsNullOrEmpty($ProcessRequirementsList))) {
        $ProcessRequirementsList.Name = $ProcessRequirementExecutable
        $ProcessRequirementsList.DisplayInfo[0].DisplayName = $ProcessRequirementDisplayName
        $ProcessRequirementsList
        $DestApplication.DeploymentTypes[$DestDeploymentTypeIndex].Installer.InstallProcessDetection.ProcessList.Add($ProcessRequirementsList)
    }
 
    # push changes
    $CMApplication = ConvertFrom-CMApplication -Application $DestApplication
    $CMApplication.Put()
    Pop-Location
}

$SCCMSite = "SITENAME:"
Import-Module ConfigurationManager

New-CMDeploymentTypeProcessRequirement -SourceApplicationName "SourceAppwithProcessRequirementdefined" -DestApplicationName "DestinationAppName" -DestDeploymentTypeName "DestinationDepType" -ProcessRequirementDisplayName "Microsoft Outlook" -ProcessRequirementExecutable "Outlook.exe"
