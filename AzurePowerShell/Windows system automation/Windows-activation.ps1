<#
 Author: GTKrishna
 File: Windows Activation on domain machine getting key from Azure Key Vault
 Description: Windows Activation on domain machine getting key from Azure Key Vault
 Date: 13/19/2024
#>



############Logger################

function logger ( $site,$type, $message, $origin ) {
    if (!(Test-Path -Path "C:\Temp\Log")) {
        New-Item -ItemType Directory -Path "C:\Temp\Log" | Out-Null
    }
    $path = "C:\Temp\Log\logfile.log"
    $value = (Get-Date -Format "dd-MM-yyyy-hh-mm").ToString() + ' ' + $site + ' ' + $ENV:COMPUTERNAME +  ' ' + $type + ' ' + $message + ' ' + $origin
    Add-Content -Path $path -Value $value
}

### Get Logged on User
function Get-Loggedon-user-Domain()
{
try
{
$CurrentUser = Get-Itemproperty "Registry::\HKEY_USERS\*\Volatile Environment"|Where-Object {$_.USERDOMAIN -match 'AzureAD' -or $_.USERNAME -match 'WDAGUtilityAccount'}
if($CurrentUser -ne $null)
{
$CurrentLoggedOnUser = "$($CurrentUser.USERDOMAIN)\$($CurrentUser.USERNAME)"
$CurrentLoggedOnUserSID = split-path $CurrentUser.PSParentPath -leaf
$DomainInfo=(Get-ItemProperty "hklm:\SOFTWARE\Microsoft\IdentityStore\Cache\$CurrentLoggedOnUserSID\IdentityCache\$CurrentLoggedOnUserSID").Username
[string]$tenant = ($DomainInfo -split '@')[1]
return $tenant
}
}
catch { 
# Handle the exception
Write-Host "An error occurred: $_"
}
}

## Windows OS Check

Function Check-OSWindows10Version()
{
    #OS Version Check
  
    $TabletOS = (Get-WmiObject -class Win32_OperatingSystem).Caption
	$TabletOSName =(Get-WmiObject -Class win32_operatingsystem).Version
	$TabletOSNum = [int]($TabletOSName |%{$_.Split('.')[0];})
    if($TabletOSNum -eq 10 -and $TabletOS -eq "Microsoft Windows 10 IoT Enterprise LTSC")
    {        
        
        $OSPreCheckPassed = $true
        logger Success "Running Windows OS version is $TabletOSNum $TabletOS" Check-OSWindows10Version.ps1
        
    } else
    {
       
        $OSPreCheckPassed = $false
        logger Fail "This Device is not Running on Windows 10, Current OS version: $TabletOSNum  Current OS type: $TabletOS" Check-OSWindows10Version.ps1
    }
    return $OSPreCheckPassed
}

Function Check-Windows-Activation-status()
{
   $output = & cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /dli
   $productName=$output | Select-String "Name" 
   $licenseStatus=$output | Select-String "License status"
   $productDetails=$output | Select-String "Description"
   # Check if the activation status contains "Licensed"
   if ($licenseStatus -match "Licensed") 
   {
     Write-Host "System Configuration activated."
     logger Success "System Configuration Success! with $productName $productDetails"
     Remove-Item -Path $Cpath -Force
  }  
}

### Main Script
#Check for Windows 10 OS Version
$OSPreCheckPassed = Check-OSWindows10Version
if($OSPreCheckPassed)
{
 $TempDir="C:\Temp\Log"
 If (!(Test-Path $TempDir))
 {
  New-Item -ItemType Directory -Path $TempDir -Force
 }

# SAS URL to get Service Principal details 
$SAS1=""
$SAS2=""
$SAS3=""
$TempDir="C:\Temp\Log"
$machine=Get-Loggedon-user-Domain
# System Tenant check 
$tenants = @("mytenant")
$matchFound = $false
# Foreach loop to compare each string
foreach ($str in $tenants) 
{
    if ($str -eq $skvm_machine) 
    {

    switch ($str) 
      {
            "mytenant" { Invoke-WebRequest $SAS1 -OutFile "$TempDir\configtask.txt" }
            "mytenant1" { Invoke-WebRequest $SAS2 -OutFile "$TempDir\configtask.txt" }
            "mytenant2" { Invoke-WebRequest $SAS3 -OutFile "$TempDir\configtask.txt" }
      }
    
            # Set the flag to indicate a match is found
        $matchFound = $true

        # Exit the loop since a match is found
        break
    }
  }

  # Check if no match is found for Domain 
if (-not $matchFound) 
{
      logger Fail "System Configuration Failed!Non Domain Machine"
}

$Cpath="$TempDir\configtask.txt"
$data=Get-Content $Cpath | Out-String | ConvertFrom-StringData
# Replace these variables with your actual values
$tenantId = $data.Tenant
$clientId = $data.Application
$clientSecret = $data.Appvalue
$keyVaultName = $data.Keyvault
$secretName = $data.Sname

# Sign in to Azure using the Service Principal credentials
$securePassword = ConvertTo-SecureString $clientSecret -AsPlainText -Force
$psCredential = New-Object System.Management.Automation.PSCredential($clientId, $securePassword)
$WarningPreference = "SilentlyContinue"
Connect-AzAccount -ServicePrincipal -TenantId $tenantId -Credential $psCredential
$WarningPreference = "Continue"
# Get the secret from Key Vault
$Keyvalue = Get-AzKeyVaultSecret -VaultName $keyVaultName -Name $secretName -AsPlainText
try
{
Start-Process -FilePath "cscript.exe" -ArgumentList "//NoLogo", "$env:SystemRoot\System32\slmgr.vbs", "/ipk $Keyvalue" -WindowStyle Hidden -Wait
Start-Process -FilePath "cscript.exe" -ArgumentList "//NoLogo", "$env:SystemRoot\System32\slmgr.vbs", "/ato" -WindowStyle Hidden -Wait
# Check Windows activation status using slmgr.vbs
# Run slmgr.vbs /dli using cscript and capture the output
$output = & cscript.exe "$env:SystemRoot\System32\slmgr.vbs" /dli
$productName=$output | Select-String "Name" 
$licenseStatus=$output | Select-String "License status"
$productDetails=$output | Select-String "Description"
# Check if the activation status contains "Licensed"
if ($licenseStatus -match "Licensed") 
   {
     Write-Host "System Configuration activated."
     logger Success "System Configuration Success! with $productName $productDetails"
     Remove-Item -Path $Cpath -Force
  } 
else 
 {
    Write-Host "System Configuration is not activated."
    logger Fail "System Configuration Failed!"
    Remove-Item -Path $Cpath -Force
 }
}
catch {
# Handle the exception
Write-Host "An error occurred: $_"
logger Fail "An error occurred: $_"
}
} # OS check close
else { logger Fail "System is not running on Microsoft Windows 10 IoT Enterprise LTSC " Install.ps1
 }
 Disconnect-AzAccount
