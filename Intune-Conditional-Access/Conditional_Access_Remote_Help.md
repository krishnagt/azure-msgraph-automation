# Remote Help Conditional Access Setup

Remote Help in Microsoft Intune enables secure IT support sessions (screen sharing/remote control). Use Entra ID Conditional Access (CA) on the Remote Assistance Service app to enforce MFA, device compliance, and location checks for helpers only.

**Prerequisites**
- Intune Suite license (includes Remote Help)
- Global Admin or Intune Admin rights
- Remote Help app deployment to all devices done via CICD pipeline->Intune Apps.
- Helpdesk security group in Entra ID
- Add Remote Help app to multi-app Kiosk policy allowed apps list

**Implementation Steps**
1. **Create Service Principal (PowerShell)**
#Run as Global Admin

***Install-Module Microsoft.Graph -Force
Connect-MgGraph -Scopes "Application.ReadWrite.All"
New-MgServicePrincipal -AppId "1dee7b72-b80d-4e56-933d-8b6b04f9a3e2"***

**Verify:** Entra ID → Enterprise apps → "Remote Assistance Service"

2.**Create CA Policy**

Entra ID → Protection → Conditional Access → New policy

| Setting                       | Configuration                                |
| ----------------------------- | -------------------------------------------- |
| Name                          | Remote Help - Secure Access                  |
| Assignments → Users           | Helpdesk group❌ Exclude: Break-glass admins  |
| Target Resources              | Cloud apps → Remote Assistance Service       |
| Conditions → Device platforms | Windows 11+                                  |
| Conditions → Locations        | ❌ Exclude trusted IPs✅ Block risky locations |
| Grant controls                | ✅ Require MFA✅ Require device compliance     |
| Session controls              | Sign-in frequency: 24 hours                  |
| Enable policy                 | Report-only → On                             |

3.**Intune Endpoint Prep**
Compliance Policy Requirements:
- ✅ BitLocker enabled
- ✅ Windows 11+ updated
- ✅ Defender real-time protection
- ✅ Remote Help app deployed (Win32/Store)

4.**CICD Pipeline Integration**

✅ Remote Help app deployment:
Azure DevOps/GitHub → Win32 package → Intune Apps
- Required: All managed endpoints
- Detection: App version check
- Supersedence: Auto-update via CICD
- Compliance: BitLocker + Defender enforced

5. **Test Flow**

Helpdesk launches Remote Help (CICD-deployed app)
↓

Entra prompts MFA (CA policy)
↓

Helper device compliance check (Intune)
↓

Location validation (corporate IP/VPN)
↓

✅ Session → Screen share/control on target (CICD app ready)
❌ Blocked → Sign-in logs + Teams alert

