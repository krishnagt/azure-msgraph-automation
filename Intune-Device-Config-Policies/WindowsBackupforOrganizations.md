# Windows Backup for Organizations - Intune Setup
Windows Backup for Organizations automatically backs up user settings, apps, and credentials to Entra ID, enabling seamless restore during OOBE on new devices.

**Prerequisites** 
- Windows 11 24H2+ devices (Entra joined)
- Intune admin rights
- Remote Help

**Simple Implementation Steps**
1. Enable Backup Policy (Settings Catalog)
   - Intune Admin Center → Devices → Configuration profiles → Create profile

- Platform: Windows 10 and later
- Profile type: Settings catalog
- Name: "Enable Windows Backup"

**Settings**
- Administrative Templates → Windows Components → Sync your settings
✅ Enable Windows Backup = Enabled

- Assignments: All devices group
- Deploy: Save → Assign

2.**Enable Restore (Tenant-Wide)**

Intune Admin Center → Devices → Enrollment → Windows tab
Enrollment options → Windows Backup and Restore (preview)
✅ Show restore page = On

3.**Test Flow**
- Device syncs → Windows Backup policy applies
- User Settings → Windows Backup → Shows "Managed by organization"
- New device OOBE → Restore from backup option appears
- Helpdesk uses Remote Help if restore fails
