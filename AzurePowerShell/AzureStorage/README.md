# AzureFileShareAndUpload.ps1

## 📌 Overview
This PowerShell script automates **Azure Storage file share creation and file uploads**.  
It performs the following tasks:

- Installs and imports the **Az.Storage** module (if not already installed).  
- Connects to an **Azure Storage Account** using account name and key.  
- Creates **two file shares** (`lib` – 5GB and `docs` – 3GB).  
- Builds a **folder hierarchy** for solution binaries and documents:  
  - `lib/<solution>/<version>/<component>/<componentversion>/<files>` → `.zip`, `.exe`, `.msi`, `.gz`, `.tar`  
  - `docs/<solution>/<version>/<files>` → `.pdf`, `.docx`, `.xml`  
- Uploads files to the respective folders.  
- Generates **SAS download URIs** for uploaded files and saves them in `output.txt`.  

---

## ⚙️ Prerequisites
- **PowerShell 7+**  
- **Az.Storage Module** (installed automatically if missing)  
- Access to an Azure Storage Account (with **Storage Account Key**)  

---

## 📝 Parameters

| Parameter            | Type   | Description |
|----------------------|--------|-------------|
| `SourcePath`         | String | Local directory containing files to upload (.zip, .exe, .msi, .gz, .tar, .pdf, .docx, .xml). |
| `StorageAccountName` | String | Azure Storage account name. |
| `StorageAccountKey`  | String | Storage account access key (for authentication). |
| `sln`                | String | Solution name (e.g., `xyz`). |
| `buildversion`       | String | Solution version (e.g., `1.0.0`). |
| `cname`              | String | Component name (e.g., `abcd`). |
| `cversion`           | String | Component version (e.g., `2.0.1`). |
| `flag`               | String | If set to `true`, overwrites files in storage (`-Force`). |

---

## ▶️ Example Usage

```powershell
# Run script with parameters
.\azure_storage_upload.ps1 `
  "C:\Users\azure-test-upload" `
  "testaccount" `
  "MJ88i/BD77g95aOk24K3DU/aWd3TUKhyK9ZV" `
  "testfolder1" `
  "1.0.0" `
  "testfolder2" `
  "2.0.1" `
  "true"

## 📂 Folder Structure Example
### For binaries (lib):
lib/
 └── testfolder1/
      └── 1.0.0/
           └── testfolder2/
                └── 2.0.1/
                     ├── app.msi
                     ├── tool.zip
                     └── setup.exe

### For documents (docs):
docs/
 └── testfolder1/
      └── 1.0.0/
           ├── design.docx
           ├── manual.pdf
           └── config.xml

## 🔄 Flow of Operations
+-----------------------------+
| Start Script Execution      |
+-------------+---------------+
              |
              v
+-----------------------------+
| Install Az.Storage module   |
| (if not already installed)  |
+-------------+---------------+
              |
              v
+-----------------------------+
| Connect to Azure Storage    |
| (StorageAccount + Key)      |
+-------------+---------------+
              |
              v
+-----------------------------+
| Create File Shares:         |
|  - lib (5 GB)               |
|  - docs (3 GB)              |
+-------------+---------------+
              |
              v
+-----------------------------+
| Create Directory Structure  |
|  lib/<solution>/<version>/  |
|      <component>/<cversion> |
|  docs/<solution>/<version>/ |
+-------------+---------------+
              |
              v
+-----------------------------+
| Upload Files:               |
|  - Installers → lib/        |
|  - Docs → docs/             |
+-------------+---------------+
              |
              v
+-----------------------------+
| Generate SAS URIs for files |
| Save to output.txt          |
+-------------+---------------+
              |
              v
+-----------------------------+
| End Script Execution        |
+-----------------------------+
```
## 📤 Output
Script logs actions (create/upload) in the console with color codes.

Creates a file output.txt with SAS URIs for uploaded files, e.g.:
Download URI for uploaded files
https://<storageaccount>.file.core.windows.net/lib/testfolder1/1.0.0/testfolder2/2.0.1/app.msi?sv=...
https://<storageaccount>.file.core.windows.net/docs/testfolder1/1.0.0/manual.pdf?sv=...

## ⚠️ Notes
Use flag = "true" to overwrite files during upload.

After execution, the script resets execution policy back to Restricted.

Do not commit your Storage Account Keys into source control.

