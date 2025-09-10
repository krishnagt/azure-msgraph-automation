# Intune Offboarding Tool

A PowerShell + WPF GUI tool for managing and offboarding Windows devices from **Microsoft Intune**, **Autopilot**, and **Azure AD**.  

This tool allows IT admins to quickly **search, view, and remove** devices from multiple Microsoft 365 services using the **Microsoft Graph API**.

---

## ✨ Features
- 🔐 **Graph API Authentication**  
  Connects to Microsoft Graph with required Intune and Directory permissions.

- 📦 **Module Management**  
  Installs and validates required Microsoft Graph PowerShell modules:
  - `Microsoft.Graph.Identity.DirectoryManagement`
  - `Microsoft.Graph.DeviceManagement`
  - `Microsoft.Graph.DeviceManagement.Enrollment`

- 🔍 **Device Search**  
  Search devices by **name** and retrieve details:
  - Device Name
  - Serial Number
  - OS
  - Assigned User
  - Enrollment/Compliance Status

- 📊 **Status Dashboard**  
  Displays if the device exists in:
  - Intune
  - Autopilot
  - Azure AD

- 🗑 **Offboarding**  
  Remove device entries from:
  - **Intune**
  - **Autopilot**
  - **Azure AD**

- ⚠️ **Error Handling**  
  Clear message boxes for invalid searches or failed actions.

---

## 📂 Requirements
- Windows PowerShell 5.1 or PowerShell 7.x
- Microsoft Graph PowerShell modules:
  ```powershell
  Install-Module Microsoft.Graph.Identity.DirectoryManagement
  Install-Module Microsoft.Graph.DeviceManagement
  Install-Module Microsoft.Graph.DeviceManagement.Enrollment

## Usage
- Clone this repo or download the script.
- Run PowerShell as Administrator.
- Execute the script:
  .\Intune-Offboarding-Tool.ps1
- Authenticate to Microsoft Graph when prompted.
- Enter a Device Name and click Search.
- Review the device status and click Offboard to remove from Intune, Autopilot, and Azure AD.

## 🖼 Screenshots
<img width="561" height="262" alt="image" src="https://github.com/user-attachments/assets/20a00c84-7d67-4db2-a3e6-7e4a61d58d0a" />

## ⚠️ Disclaimer

This script is provided as-is.
Use in test environments before production deployment.
Requires sufficient Graph API permissions to manage Intune and Azure AD devices.
