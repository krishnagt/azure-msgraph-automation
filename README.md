# Enterprise Endpoint Platform Architecture
**Zero Trust for 500+ Regulated Windows 10 Kiosks**  

## Architecture Overview

Enterprise Endpoint Platform Architecture (Zero Trust for 500+ Kiosks)

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




## Key Implementation Highlights

### 🔐 **Identity & Access Layer**
- **Azure Entra ID**: All 500+ kiosks Azure AD joined with RBAC for developers
- **Conditional Access + MFA**: Device trust signals integrated with CA policies
- **Azure Key Vault**: Windows activation keys + BitLocker escrow management

### 🛡️ **Security & Compliance Layer**
- **CIS Benchmarks**: 100% compliance via Intune configuration profiles
- **BitLocker**: Enterprise encryption with automated key recovery
- **Microsoft Defender for Endpoint**: Onboarding + real-time threat protection
- **Device Restrictions**: Kiosk lockdown with Assigned Access (limited apps)

### 📱 **Endpoint Management Layer**
- **Intune Autopilot**: Zero-touch provisioning with Zero Trust validation
- **Kiosk Mode**: 500+ Windows 10 endpoints with approved app restrictions
- **Win32 App CI/CD**: Automated installer packaging/deployment via Azure DevOps
- **Windows Patching**: Ring-based updates via Intune + AWS SSM Patch Manager

### 📊 **Observability Layer**
- **Azure Monitor Agent (AMA)**: Telemetry collection for Log Analytics
- **AWS SSM Hybrid**: Cross-cloud script execution and SSH access
- **Real-time Monitoring**: Application health + L3/L4 support dashboards

## 🏗️ **Architecture Flow**

PROVISION → Intune Autopilot + Entra ID Join
↓

SECURE → CIS Policies + BitLocker + Defender Onboarding
↓

OPERATE → Kiosk Lockdown + App Deployment + Patching
↓

MONITOR → AMA Logs → Self-Healing Remediation (Intune + SSM)


## 📈 **Business Impact**
- **40%** faster endpoint onboarding via zero-touch provisioning
- **100%** CIS benchmark compliance across regulated healthcare kiosks
- **Eliminated** 3rd-party MDM tooling costs
- **Self-healing** configuration drift detection/remediation
- **High Availability** operations for mission-critical healthcare platforms

**GitHub**: [azure-msgraph-automation](github.com/krishnagt/azure-msgraph-automation)
