#
# Press 'F5' to run this script. Running this script will load the ConfigurationManager
# module for Windows PowerShell and will connect to the site.
#
# This script was auto-generated at '10/27/2022 8:25:38 AM'.

# Site configuration
$SiteCode = "XXXXXXX" # Site code 
$ProviderMachineName = "XXXXXXXXXXX" # SMS Provider machine name

# Customizations
$initParams = @{}
#$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
#$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

# Do not change anything below this line

# Import the ConfigurationManager.psd1 module 
if((Get-Module ConfigurationManager) -eq $null) {
    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams 
}

# Connect to the site's drive if it is not already present
if((Get-PSDrive -Name $SiteCode -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
    New-PSDrive -Name $SiteCode -PSProvider CMSite -Root $ProviderMachineName @initParams
}

# Set the current location to be the site code.
Set-Location "$($SiteCode):\" @initParams






$securityGroupOUPath = "OU=XXX,OU=XXX,OU=XXX,DC=XXX,DC=XXX,DC=XXX"

$confirmation = $false

# Get information about publisher and software
while(-not $confirmation){
    $publisherName = Read-Host "Enter the name of the publisher"
    $softwareName = Read-Host "Enter the name of the software"

    $publisherName = $publisherName.Replace(" ", "")
    $softwareName = $softwareName.Replace(" ", "")

    $ADSecurtiyGroupInstallName = "WEM " + $publisherName + " " + $softwareName + " Install"
    $ADSecurtiyGroupUninstallName = "WEM " + $publisherName + " " + $softwareName + " Uninstall"

    $SoftwareCollectionInstallName = $publisherName + "-" + $softwareName + "-Install"
    $SoftwareCollectionUninstallName = $publisherName + "-" + $softwareName + "-Uninstall"
    
    Write-Host "The following AD Groups shall be created" -ForegroundColor Yellow
    Write-Host $ADSecurtiyGroupInstallName -ForegroundColor Green
    Write-Host $ADSecurtiyGroupUninstallName -ForegroundColor Green
    Write-Host "The following Device Collection Groups shall be created" -ForegroundColor Yellow
    Write-Host $SoftwareCollectionInstallName -ForegroundColor Green
    Write-Host $SoftwareCollectionUninstallName -ForegroundColor Green

    $userInput = Read-Host "`nDoes this look good to you? If so, enter y"
    if($userInput -eq "y"){$confirmation = $true}
}


# Create the security groups in AD
New-ADGroup $ADSecurtiyGroupInstallName -GroupScope Global -GroupCategory Security -Path $securityGroupOUPath
New-ADGroup $ADSecurtiyGroupUninstallName -GroupScope Global -GroupCategory Security -Path $securityGroupOUPath

# Create the device collections (install & uninstall) in SCCM
New-CMDeviceCollection -Name $SoftwareCollectionInstallName -LimitingCollectionName 'All Non-Server Systems'
New-CMDeviceCollection -Name $SoftwareCollectionUninstallName -LimitingCollectionName 'All Non-Server Systems'

# Find the newly created device collections in SCCM
$softwareInstallCollection = Get-CMDeviceCollection -Name $SoftwareCollectionInstallName
$softwareUninstallCollection = Get-CMDeviceCollection -Name $SoftwareCollectionUninstallName

# Move the newly created device collections in SCCM to the Software Installation and Removal folder under Device Collection
Move-CMObject -InputObject $softwareInstallCollection -FolderPath ($SiteCode+':\DeviceCollection\Software Installation and Removal')
Move-CMObject -InputObject $softwareUninstallCollection -FolderPath ($SiteCode+':\DeviceCollection\Software Installation and Removal')



# Specify the query needed for the device collection
$wqlInstall = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "XXX\\' + $ADSecurtiyGroupInstallName + '"'
$wqlUninstall = 'select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Name,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup,SMS_R_SYSTEM.Client from SMS_R_System where SMS_R_System.SystemGroupName = "XXX\\' + $ADSecurtiyGroupUninstallName + '"'

# Add query for device collection
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $SoftwareCollectionInstallName -QueryExpression $wqlInstall -RuleName $SoftwareCollectionInstallName
Add-CMDeviceCollectionQueryMembershipRule -CollectionName $SoftwareCollectionUninstallName -QueryExpression $wqlUninstall -RuleName $SoftwareCollectionUninstallName
