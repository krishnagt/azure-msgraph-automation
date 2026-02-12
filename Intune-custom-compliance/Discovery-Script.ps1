# Intune Custom Compliance Discovery Script
# Checks:
# 1. OS minimum version (Windows 10 LTSC)
# 2. BitLocker on system drive
# 3. SSM agent installed
# 4. Password complexity enabled
# 5. Chrome browser version
# 6. Secure Boot state
# 7. Drive encryption status (system drive)

$Result = @{}

# 1) OS minimum version (Windows 10 LTSC example)
# You can adjust MinVersion as needed (e.g. 10.0.17763.0 for 1809 LTSC)
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $currentVersion = [version]$os.Version
    $minVersion     = [version]"10.0.17763.0"  # Example: Win10 1809 LTSC

    if ($currentVersion -ge $minVersion) {
        $Result["OSMinVersionMet"] = $true
    } else {
        $Result["OSMinVersionMet"] = $false
    }

    # Also expose current version as a string if you want to use Version datatype
    $Result["OSBuildVersion"] = $os.Version
}
catch {
    $Result["OSMinVersionMet"] = $false
    $Result["OSBuildVersion"]  = "Unknown"
}

# 2) BitLocker on system drive (assume C:)
try {
    $blv = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
    if ($blv.ProtectionStatus -eq 'On' -or $blv.ProtectionStatus -eq 1) {
        $Result["BitLockerCDriveOn"] = $true
    } else {
        $Result["BitLockerCDriveOn"] = $false
    }
}
catch {
    $Result["BitLockerCDriveOn"] = $false
}

# 3) SSM agent installed (Windows service check)
# Service name is usually AmazonSSMAgent
try {
    $ssmSvc = Get-Service -Name "AmazonSSMAgent" -ErrorAction SilentlyContinue
    if ($null -ne $ssmSvc -and $ssmSvc.Status -ne "Stopped") {
        $Result["SSMAgentInstalled"] = $true
    } elseif ($null -ne $ssmSvc) {
        # Installed but not running
        $Result["SSMAgentInstalled"] = $true
    } else {
        $Result["SSMAgentInstalled"] = $false
    }
}
catch {
    $Result["SSMAgentInstalled"] = $false
}

# 4) Password should be strong (basic local policy check)
# This uses "Password must meet complexity requirements" and minimum length
try {
    $secpol = secedit.exe /export /cfg "$env:TEMP\secpol.cfg" /quiet
    $cfg    = Get-Content "$env:TEMP\secpol.cfg"

    $complexityLine = $cfg | Where-Object { $_ -match "^PasswordComplexity\s*=" }
    $minLenLine     = $cfg | Where-Object { $_ -match "^MinimumPasswordLength\s*=" }

    $complexity = 0
    $minLen     = 0

    if ($complexityLine) {
        $complexity = [int]($complexityLine.Split("=")[1].Trim())
    }
    if ($minLenLine) {
        $minLen = [int]($minLenLine.Split("=")[1].Trim())
    }

    # Adjust rules as per your standard: complexity=1 and min length >= 8
    if ($complexity -eq 1 -and $minLen -ge 8) {
        $Result["PasswordStrongPolicy"] = $true
    } else {
        $Result["PasswordStrongPolicy"] = $false
    }
}
catch {
    $Result["PasswordStrongPolicy"] = $false
}

# 5) Chrome Browser Version (any latest version you define)
# We just report the version; you enforce min version via JSON rule
try {
    $chromePath = "HKLM:\SOFTWARE\Google\Chrome\BLBeacon"
    $chromeVer  = (Get-ItemProperty -Path $chromePath -ErrorAction Stop).version
    $Result["ChromeVersion"] = $chromeVer
}
catch {
    # Try 64-bit Wow6432Node path as fallback
    try {
        $chromePath = "HKLM:\SOFTWARE\WOW6432Node\Google\Chrome\BLBeacon"
        $chromeVer  = (Get-ItemProperty -Path $chromePath -ErrorAction Stop).version
        $Result["ChromeVersion"] = $chromeVer
    }
    catch {
        $Result["ChromeVersion"] = "NotInstalled"
    }
}

# 6) Secure Boot state
try {
    # Requires UEFI system with Secure Boot
    $sb = Confirm-SecureBootUEFI -ErrorAction Stop
    $Result["SecureBootEnabled"] = [bool]$sb
}
catch {
    # If command fails (e.g. BIOS, no UEFI), treat as not enabled
    $Result["SecureBootEnabled"] = $false
}

# 7) Drive encryption (system drive, BitLocker status)
# Reuse BitLocker info but expose more detail
try {
    if ($null -eq $blv) {
        $blv = Get-BitLockerVolume -MountPoint "C:" -ErrorAction Stop
    }
    $Result["SystemDriveEncryptionStatus"] = $blv.ProtectionStatus.ToString()
}
catch {
    $Result["SystemDriveEncryptionStatus"] = "Unknown"
}

# Output compressed JSON for Intune
$Result | ConvertTo-Json -Compress
