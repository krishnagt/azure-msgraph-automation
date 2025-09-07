# NAME: Deploy-Win32AppToIntune.ps1
# AUTHOR: Krishna G T
# DATE: 02/05/2023
#
# KEYWORDS: Azure, Intune, Microsoft Graph, PowerShell, Win32App, Endpoint Manager
#
# COMMENTS:
# This script automates the packaging and deployment of Win32 applications to Microsoft Intune.  
# It connects to Azure AD and Intune (via Microsoft Graph API) using either interactive or non-interactive mode.  
# If required modules are not installed (Microsoft.Graph.Intune, IntuneWin32App), it installs and imports them.  
#
# Key actions performed by this script:
# 1. Connect to Azure AD and Intune with provided credentials or interactive login.
# 2. Package the Win32 application into `.intunewin` format using `New-IntuneWin32AppPackage`.
# 3. Retrieve application metadata (`Get-IntuneWin32AppMetaData`).
# 4. Define application details such as Display Name, Description, Publisher.
# 5. Configure detection rules and requirement rules for the application.
# 6. Set install/uninstall command lines.
# 7. Upload and publish the packaged application to Intune using `Add-IntuneWin32App`.
#
# INPUT PARAMETERS:
# - $credentials : (Optional) PSCredential object for non-interactive execution.
# - $Source      : Source folder containing application installer files.
# - $SetupFile   : Name of the installer executable (e.g., App.exe).
# - $Destination : Local folder path to generate the .intunewin package.
#
# OUTPUT:
# - A packaged Win32 app uploaded and deployed to Microsoft Intune with configured rules and metadata.
#
# EXAMPLE:
# .\Deploy-Win32AppToIntune.ps1
#
# Running in interactive mode will prompt for login.  
# Running in non-interactive mode requires providing PSCredential and environment variables:
#   $securePassword = ConvertTo-SecureString "password" -AsPlainText -Force
#   $cred = New-Object System.Management.Automation.PSCredential("username@domain.com", $securePassword)
#   .\Deploy-Win32AppToIntune.ps1 -credentials $cred
#
# Example variables inside script:
#   $Source = "C:\Source\App"
#   $SetupFile = "App.exe"
#   $Destination = "C:\temp\AppPackage"
#   $DisplayName = "My App Installer"
#   $Description = "Installer for My App"
#   $Publisher = "MyCompany"
#
# The script then packages the installer, applies detection/requirement rules,
# and uploads it to Intune for deployment to managed endpoints.


#Pass the credentials if running in non-interactive mode
#If running in interactive mode , will have to sign in from pop-up and credentials will not be passed
function Connect-Intune()
{
[CmdletBinding()]
param (
    
    [Parameter()]
    [System.Management.Automation.PSCredential]
    $credentials
)

# Checking if the Microsoft.Graph.Intune module us installed
try
{
$IntuneModule = Get-Module -Name "Microsoft.Graph.Intune" -ListAvailable
 if ($null -eq $IntuneModule) 
   {
        write-host
        write-host "The module Microsoft.Graph.Intune was not found..." -f Red
        write-host "Installing by running the command 'Install-Module Microsoft.Graph.Intune' from an elevated PowerShell prompt" -f Yellow
        Install-Module Microsoft.Graph.Intune
        write-host
    }
 Else
   {
    Import-Module Microsoft.Graph.Intune -ErrorAction SilentlyContinue
   }
 }
 catch
 {
 [MahApps.Metro.Controls.Dialogs.DialogManager]::ShowMessageAsync($Form, "Oops :-(", "Can not import the Intune module")                                     
   Break
 }

   # Checking if the Microsoft.Graph.Intune module us installed
try
{
$IntuneWin32App = Get-Module -Name IntuneWin32App -ListAvailable
 if ($null -eq $IntuneWin32App)
  {
        write-host
        Install-Module -Name "IntuneWin32App" -Force
        # Explore the module
        Get-Command -Module "IntuneWin32App"
        write-host
}
 Else
   {
    Import-Module IntuneWin32App -ErrorAction SilentlyContinue
   }
 }
 catch
 {
 Break
 }
#. ".\utils\logger.ps1"
 if ($env:USERDOMAIN -ne "code1") {
    Write-Host "Script can be run only on Company Authorized machines." -ForegroundColor Red
    throw "Host Machine Authorization Error"
}
try {
    if ($null -ne $credentials) {
        Update-MSGraphEnvironment -SchemaVersion beta
        $response1 = Connect-MSGraph -Credential $credentials -ErrorAction Stop
    }
    else {
        Update-MSGraphEnvironment -SchemaVersion beta
        $response1 = Connect-MSGraph -ErrorAction Stop
    }
    write-host "`n Intune Logged in user :" $response1.UPN -ForegroundColor Yellow
    #logger -type "Info" -origin ".\functions\Connect-Intune.ps1" -message (($response.Context.Account.Id) + " has logged in")
}
catch {
    write-host "`nUnable To Login" -ForegroundColor Red
    #logger -type "Error" -origin ".\functions\Connect-Intune.ps1" -message $Error[0].toString()    
}
}

## Getting region information to login
$json =".\config\installer_version.json"
$data = Get-Content $json| Out-String | ConvertFrom-Json
#$domainName=$data.'Domain details'.$regionIdentifier
$domainName=$data.'Domain details'.'D'
if ($null -ne $domainName -and $null -ne $ENV:tenantPassword) {
    $secureStringPassword = ConvertTo-SecureString "$($ENV:tenantPassword)" -AsPlainText -Force
    $credentials = New-Object System.Management.Automation.PSCredential("$ENV:Username@$domainName", $secureStringPassword)
 ## Connect to Azure Ad and Intune 
    connect -credentials $credentials #pass credentials for account login
	  Connect-Intune -credentials $credentials 
}
 else {
        connect 
		Connect-Intune
      }

If ((Get-MSGraphEnvironment).SchemaVersion -ne "beta")
{
    $null = Update-MSGraphEnvironment -SchemaVersion beta
}

#Create the intunewin file from source and destination variables
$Source = <Final Package Folder>
$SetupFile = "<App.exe>"
$Destination = "C:\temp\App.exe"
$CreateAppPackage = New-IntuneWin32AppPackage -SourceFolder $Source -SetupFile $SetupFile -OutputFolder $Destination -Verbose
$IntuneWinFile = $CreateAppPackage.Path

#Get intunewin file Meta data and assign intunewin file location variable
$IntuneWinMetaData = Get-IntuneWin32AppMetaData -FilePath $IntuneWinFile

#Names Application, description and publisher info
$Displayname = "APP Installer"
$Description = "Installer for APP Set up"
$Publisher = "ABC"

# Create File exists detection rule - Retrieve MSI code if you don't have it. Alternate method commented below to use File existence. MSIs are recommended to use Product Code. 
#$DetectionRule = New-IntuneWin32AppDetectionRuleMSI -ProductCode $IntuneWinMetaData.ApplicationInfo.MsiInfo.MsiProductCode
$DetectionRule = New-IntuneWin32AppDetectionRuleFile -Existence -FileOrFolder philips -Path "C:\Program Files (x86)" -Check32BitOn64System $false -DetectionType "exists"

#Create Requirement Rule
$RequirementRule = New-IntuneWin32AppRequirementRule -Architecture x64 -MinimumSupportedOperatingSystem 1607
 
#Create a cool Icon from an image file (if you want)
#$ImageFile = "$appfolder\$LogoFileName"
#$Icon = New-IntuneWin32AppIcon -FilePath $ImageFile
 
###Install and Uninstall Commands - not needed for MSI installs
$InstallCommandLine = "test.exe /install /quiet"
$UninstallCommandLine = "test.exe /uninstall"

#Builds the App and Uploads to Intune
Add-IntuneWin32App -FilePath $IntuneWinFile -DisplayName $DisplayName -Description $Description -Publisher $Publisher -InstallExperience "system" -RestartBehavior "suppress" -DetectionRule $DetectionRule -RequirementRule $RequirementRule -InstallCommandLine $InstallCommandLine -UninstallCommandLine $UninstallCommandLine -Verbose
