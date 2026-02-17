** Enterprise Endpoint Platform Architecture (Zero Trust for 500+ Kiosks) **

+-------------------+     +-------------------+     +-------------------+
|   Azure Entra ID  |<--->|   Intune MDM      |<--->|   AWS SSM Hybrid  |
| - AAD Join        |     | - Autopilot ZT    |     | - Scripts/SSH     |
| - CA/MFA          |     | - Kiosk Assigned  |     | - Patch Manager   |
| - RBAC            |     | - App CI/CD       |     |                   |
+-------------------+     +-------------------+     +-------------------+
          |                         |                         |
          v                         v                         v
+-------------------+     +-------------------+     +-------------------+
| Azure Key Vault   |     |   Compliance      |     |   Log Analytics   |
| - BitLocker Keys  |     | - CIS Benchmarks  |     | - AMA Telemetry   |
| - Activation      |     | - Encryption      |     | - Monitoring      |
+-------------------+     +-------------------+     +-------------------+
          |                         |                         |
          +------------|--------------|------------+ 
                       v
              +-------------------+
              | 500+ Win10 Kiosks |
              | - Defender EDR    |
              | - Patching        |
              | - Self-Healing    |
              +-------------------+

Flow: Provision (Autopilot) → Secure (ZT Policies) → Monitor/Remediate (Logs + SSM)
