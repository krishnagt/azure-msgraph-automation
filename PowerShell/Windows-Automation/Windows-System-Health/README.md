# Enable-Telemetry-Alerts.ps1

## 📌 Overview
This PowerShell script automates the creation and scheduling of a monitoring script (`Monitoring.ps1`) that tracks **critical Windows system events** and logs them locally.  
It is designed for proactive monitoring of device health and can be integrated with **Azure Log Analytics** or other monitoring pipelines.

---

## 🔧 Features
- ✅ Generates a monitoring script (`Monitoring.ps1`) under `C:\Temp\Log\`
- ✅ Captures key system events:
  - System restarts & shutdowns
  - System crashes (Event IDs 41, 1001)
  - Network disconnections (Event ID 27)
  - Battery health (capacity vs design threshold)
  - Battery power status (plugged in or running on battery)
- ✅ Logs events with timestamp, device name, severity, and message
- ✅ Creates a **Windows Scheduled Task** to run monitoring every 5 minutes
- ✅ Ensures idempotency (reuses or updates existing task if already created)

---

## 📂 Log Output
Logs are stored at:

C:\Temp\Log\Monitoring.Log
14/Feb/2022:12:30:00 +0530 SystemName MYPC Status:Critical Message: System Restarted at 14/Feb/2022 12:25:00 Unexpected Restart


---

## ▶️ Usage
1. Run the script with administrative privileges:
   ```powershell
   .\Enable-Telemetry-Alerts.ps1
## The script will:

- Generate Monitoring.ps1
- Create (or update) a scheduled task named "Monitoring Script"
- Schedule it to run every 5 minutes under SYSTEM
- Verify the scheduled task:

Get-ScheduledTask -TaskName "Monitoring Script" -TaskPath "\Azure\"

## 📊 Integration
- The log file (Monitoring.Log) can be ingested into:
- Azure Log Analytics (via MMA or AMA agent)
- Splunk
- Any SIEM / monitoring solution
