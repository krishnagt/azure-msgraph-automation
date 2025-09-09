# Windows Activation via Azure Key Vault

## 📌 Overview
This PowerShell script automates **Windows activation on domain-joined machines** using a product key stored in **Azure Key Vault**.  
It validates the OS type, retrieves activation keys securely, applies the key using `slmgr.vbs`, and logs results for audit purposes.

---

## ⚙️ Features
- Checks if the system is running **Windows 10 IoT Enterprise LTSC**.
- Validates that the machine belongs to an approved domain/tenant.
- Retrieves **Service Principal details** from a secured configuration file.
- Connects to **Azure** using Service Principal authentication.
- Fetches the **Windows activation key from Azure Key Vault**.
- Executes **slmgr.vbs** commands to install and activate the product key.
- Logs all results (success/failure) to `C:\Temp\Log\logfile.log`.

---

## 📝 Prerequisites
- Windows 10 IoT Enterprise LTSC  
- PowerShell 5.1 or later  
- Azure PowerShell `Az` Module installed (`Install-Module Az -Scope CurrentUser`)  
- Access to:
  - Azure Key Vault containing activation key  
  - Service Principal with `Key Vault Secrets User` permissions  
- Domain-joined machine with correct tenant  

---

## 📝 Parameters / Config
- **Tenant information** (Tenant ID, Client ID, Secret) stored in a temporary config file retrieved via SAS URL.  
- **Key Vault Name** and **Secret Name** for product key.  
- **Log Path:** `C:\Temp\Log\logfile.log`  

---

## ▶️ Usage
Run the script in PowerShell (as Administrator):

```powershell
.\Activate-WindowsFromKeyVault.ps1
