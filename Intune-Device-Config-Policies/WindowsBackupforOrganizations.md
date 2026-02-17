# Windows Backup for Organizations - Intune Setup
Windows Backup for Organizations automatically backs up user settings, apps, and credentials to Entra ID, enabling seamless restore during OOBE on new devices.

**Prerequisites** 
- Windows 11 24H2+ devices (Entra joined)
- Intune admin rights
- Ensure the device user must have at least one backup profile before you restore.
- Enable the Install Windows quality updates policy. If you’re on a build older than July 2025, verify that the setting Install Windows quality updates is enabled for your devices to leverage the feature.
- If Autopilot is used, the Windows Autopilot profile must be configured to use user-driven mode so that restore happens during OOBE, not self-deploying mode.
- Configure the Windows quality updates setting.

**Simple Implementation Steps**
1. Enable Backup Policy (Settings Catalog)
   - ***Intune Admin Center → Devices → Configuration profiles → Create profile***

- Platform: Windows 10 and later
- Profile type: Settings catalog
- Name: "Enable Windows Backup"

**Settings**
- ***Administrative Templates → Windows Components → Sync your settings -> Enable Windows Backup = Enabled***

- Assignments: All devices group
- Deploy: Save → Assign

2.**Enable Restore (Tenant-Wide)**

***Intune Admin Center → Devices → Enrollment → Windows tab***
***Enrollment options → Windows Backup and Restore (preview) -> Show restore page = On***

3.**Test Flow**
- Device syncs → Windows Backup policy applies
- User Settings → Windows Backup → Shows "Managed by organization"
- New device OOBE → Restore from backup option appears
- Helpdesk uses Remote Help if restore fails
