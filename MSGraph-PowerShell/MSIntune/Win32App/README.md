# Deploy-Win32AppToIntune.ps1

## 📌 Overview
This PowerShell script automates the **packaging and deployment of Win32 applications** to **Microsoft Intune (Endpoint Manager)**.  
It leverages the **Microsoft Graph Intune** and **IntuneWin32App** modules to package applications into `.intunewin` format, define detection/requirement rules, and upload them to Intune for deployment.

---

## ⚙️ Features
- Connects to **Azure AD and Intune** (interactive or non-interactive login).
- Installs required modules if missing:
  - `Microsoft.Graph.Intune`
  - `IntuneWin32App`
- Packages a Win32 installer (`.exe`, `.msi`) into `.intunewin` format.
- Extracts metadata from the generated package.
- Configures application details:
  - Display Name
  - Description
  - Publisher
- Adds **detection rules** (MSI code or file existence).
- Adds **requirement rules** (e.g., OS version, architecture).
- Defines **install/uninstall command lines**.
- Uploads and publishes the app into Intune.

---

## 📝 Prerequisites
- Windows PowerShell 5.1 or PowerShell 7+
- Admin rights to install modules if missing
- Required PowerShell modules:
  - `Microsoft.Graph.Intune`
  - `IntuneWin32App`
- Access to **Microsoft Intune tenant** with permissions to deploy applications
- Installer files ready (`.exe` or `.msi`)

---

## 📝 Parameters
| Parameter      | Type      | Description |
|----------------|-----------|-------------|
| `credentials`  | PSCredential (Optional) | Used for non-interactive authentication. If omitted, interactive sign-in is required. |

---

## ▶️ Usage

### 1️⃣ Run in Interactive Mode
```powershell
.\Deploy-Win32AppToIntune.ps1
```
- You will be prompted to sign in interactively.
### 2️⃣ Run in Non-Interactive Mode
```
$securePassword = ConvertTo-SecureString "password" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential("username@domain.com", $securePassword)
.\Deploy-Win32AppToIntune.ps1 -credentials $cred
```
### 📂 Example Configuration Inside Script
```
# Define source and installer
$Source = "C:\Source\App"
$SetupFile = "App.exe"
$Destination = "C:\temp\AppPackage"

# Application metadata
$DisplayName = "App Installer"
$Description = "Installer for App setup"
$Publisher = "MyCompany"

# Detection rule (example: check if file exists)
$DetectionRule = New-IntuneWin32AppDetectionRuleFile `
    -Existence `
    -FileOrFolder "AppFolder" `
    -Path "C:\Program Files" `
    -Check32BitOn64System $false `
    -DetectionType "exists"

# Requirement rule
$RequirementRule = New-IntuneWin32AppRequirementRule `
    -Architecture x64 `
    -MinimumSupportedOperatingSystem 1607

# Install/Uninstall commands
$InstallCommandLine = "App.exe /install /quiet"
$UninstallCommandLine = "App.exe /uninstall"
```
# 🔄 Flow of Operations
```
+----------------------------------+
| Start Script Execution           |
+----------------------------------+
                |
                v
+----------------------------------+
| Install & Import Required Modules|
+----------------------------------+
                |
                v
+----------------------------------+
| Connect to Azure AD & Intune     |
+----------------------------------+
                |
                v
+----------------------------------+
| Package Installer into .intunewin|
+----------------------------------+
                |
                v
+----------------------------------+
| Extract Metadata & Set App Props |
+----------------------------------+
                |
                v
+----------------------------------+
| Configure Detection & Requirements|
+----------------------------------+
                |
                v
+----------------------------------+
| Upload App to Intune             |
+----------------------------------+
                |
                v
+----------------------------------+
| App Available for Deployment     |
+----------------------------------+
```
## 📤 Output

A .intunewin package generated locally

Application uploaded into Intune with configured metadata, rules, and commands

App ready for deployment to managed devices

## ⚠️ Notes

Ensure Intune admin permissions before execution

Test detection/requirement rules carefully

For MSI installs, prefer MSI detection rule instead of file existence

Customize install/uninstall commands as per your installer
