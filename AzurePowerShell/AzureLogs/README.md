# Export-AzureLogsToExternalAPI.ps1

## 📌 Overview
This PowerShell script is an **Azure Automation Runbook** designed for **multi-cloud / hybrid log forwarding**.  
It collects **Azure Log Analytics events**, converts them into structured audit records, and pushes them to an **external API endpoint** (such as a third-party cloud platform, SIEM, or monitoring service).

This enables **cross-cloud observability, compliance, and integration**.

---

## ⚙️ Key Features
- Triggered via **Azure Automation Webhook**.  
- Parses **Log Analytics query results** (columns & rows).  
- Builds structured **audit event JSON payloads**.  
- Connects to Azure using **Automation RunAsConnection (Service Principal)**.  
- Retrieves credentials securely from **Azure Key Vault**.  
- Authenticates against an **external API**.  
- Pushes logs via `Invoke-RestMethod`.  
- Can be adapted for **SIEM, monitoring, or multi-cloud platforms**.  

---

## 📝 Parameters
| Parameter    | Type   | Description |
|--------------|--------|-------------|
| `WebHookData` | Object | JSON payload passed by Azure Automation Webhook. Contains Log Analytics SearchResult data. |

---

## ▶️ Usage

### 1️⃣ Import as Azure Automation Runbook
- Upload this script into Azure Automation.
- Link it to a **Webhook**.

### 2️⃣ Trigger Runbook
Send **Log Analytics query results** (JSON) to the webhook URL.  
The script will parse and forward logs to the external API.

---

## 🔄 Flow of Operations
```text
+-------------------------------+
| Trigger: Azure Webhook        |
+---------------+---------------+
                |
                v
+-------------------------------+
| Parse Log Analytics Results   |
+---------------+---------------+
                |
                v
+-------------------------------+
| Connect to Azure (RunAs SPN)  |
+---------------+---------------+
                |
                v
+-------------------------------+
| Retrieve Secrets from KeyVault|
+---------------+---------------+
                |
                v
+-------------------------------+
| Authenticate to External API  |
+---------------+---------------+
                |
                v
+-------------------------------+
| Build Audit JSON Payloads     |
+---------------+---------------+
                |
                v
+-------------------------------+
| Push Events to External API   |
+---------------+---------------+
                |
                v
+-------------------------------+
| Multi-Cloud / Hybrid Logging  |
+-------------------------------+
```
## Output

- Sends audit events to an external API.

- JSON payload includes fields like:

- eventType

- dateTime

- tenant

- componentName

- EventId / EventLevelName

Console output shows parsed records, payloads, and API responses.

## ⚠️ Notes

Replace placeholders:

1. $Uri → External API login endpoint

2. $audit_uri → External audit ingestion endpoint

3. Ensure Key Vault secrets (username, password) exist before execution.

4. Grant Automation RunAs Account Key Vault access.

5. Webhook payload must contain Log Analytics SearchResult JSON.

## 🌍 Multi-Cloud Context

This script supports hybrid and multi-cloud observability:

Source: Microsoft Azure (Log Analytics)

Destination: External Cloud / SIEM / API endpoint

It can be easily adapted for:

Splunk

Datadog

AWS CloudWatch

Elastic / OpenSearch

Any REST-capable platform
