<#
###############################################################################
# Script: Add-DeviceConfigurationPolicyAssignment.ps1
# Author: GTKrishna
#
# Description:
# This PowerShell function assigns Intune Device Configuration Policies 
# to Azure AD groups using the Microsoft Graph API.
#
# Key Features:
# - Accepts a Configuration Policy ID and Target Group ID as input.
# - Supports assignment type: Included or Excluded.
# - Checks if the group is already assigned to the policy.
# - Builds the JSON payload dynamically with existing + new assignments.
# - Submits the assignment request via Graph API (beta endpoint).
# - Handles errors gracefully with detailed Graph API response output.
#
# Example:
#   Add-DeviceConfigurationPolicyAssignment `
#       -ConfigurationPolicyId <PolicyId> `
#       -TargetGroupId <GroupId> `
#       -AssignmentType Included `
#       -authToken <AccessToken>
#
# Category:
# Intune Automation | Microsoft Graph API | Device Configuration Management
###############################################################################
#>

Function Add-DeviceConfigurationPolicyAssignment(){
[cmdletbinding()]

param
(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $ConfigurationPolicyId,

    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    $TargetGroupId,

    [parameter(Mandatory=$true)]
    [ValidateSet("Included","Excluded")]
    [ValidateNotNullOrEmpty()]
    [string]$AssignmentType,

     [parameter(Mandatory=$true)]
    [ValidateSet("Included","Excluded")]
    [ValidateNotNullOrEmpty()]
    [string]$authToken
)

$graphApiVersion = "Beta"
$Resource = "deviceManagement/deviceConfigurations/$ConfigurationPolicyId/assign"
    
    try {

        if(!$ConfigurationPolicyId){

            write-host "No Configuration Policy Id specified, specify a valid Configuration Policy Id" -f Red
            break

        }

        if(!$TargetGroupId){

            write-host "No Target Group Id specified, specify a valid Target Group Id" -f Red
            break

        }

        # Checking if there are Assignments already configured in the Policy
        $DCPA = Get-DeviceConfigurationPolicyAssignment -id $ConfigurationPolicyId

        $TargetGroups = @()

        if(@($DCPA).count -ge 1){
            
            if($DCPA.targetGroupId -contains $TargetGroupId){

            Write-Host "Group with Id '$TargetGroupId' already assigned to Policy..." -ForegroundColor Red
            Write-Host
            break

            }

            # Looping through previously configured assignements

            $DCPA | foreach {

            $TargetGroup = New-Object -TypeName psobject
     
                if($_.excludeGroup -eq $true){

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'
     
                }
     
                else {
     
                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'
     
                }

            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value $_.targetGroupId

            $Target = New-Object -TypeName psobject
            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

            $TargetGroups += $Target

            }

            # Adding new group to psobject
            $TargetGroup = New-Object -TypeName psobject

                if($AssignmentType -eq "Excluded"){

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'
     
                }
     
                elseif($AssignmentType -eq "Included") {
     
                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'
     
                }
     
            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"

            $Target = New-Object -TypeName psobject
            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

            $TargetGroups += $Target

        }

        else {

            # No assignments configured creating new JSON object of group assigned
            
            $TargetGroup = New-Object -TypeName psobject

                if($AssignmentType -eq "Excluded"){

                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.exclusionGroupAssignmentTarget'
     
                }
     
                elseif($AssignmentType -eq "Included") {
     
                    $TargetGroup | Add-Member -MemberType NoteProperty -Name '@odata.type' -Value '#microsoft.graph.groupAssignmentTarget'
     
                }
     
            $TargetGroup | Add-Member -MemberType NoteProperty -Name 'groupId' -Value "$TargetGroupId"

            $Target = New-Object -TypeName psobject
            $Target | Add-Member -MemberType NoteProperty -Name 'target' -Value $TargetGroup

            $TargetGroups = $Target

        }

    # Creating JSON object to pass to Graph
    $Output = New-Object -TypeName psobject

    $Output | Add-Member -MemberType NoteProperty -Name 'assignments' -Value @($TargetGroups)

    $JSON = $Output | ConvertTo-Json -Depth 3

    # POST to Graph Service
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"

    }
    
    catch {

    $ex = $_.Exception
    $errorResponse = $ex.Response.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($errorResponse)
    $reader.BaseStream.Position = 0
    $reader.DiscardBufferedData()
    $responseBody = $reader.ReadToEnd();
    Write-Host "Response content:`n$responseBody" -f Red
    Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
    write-host
    break

    }

}


   $Path1="C:\Temp\Intune.txt"
    $values=Get-Content $Path1 | Out-String | ConvertFrom-StringData
    $TargetGroupId=$values.AD_Group_Id
    $DCPid=$values.Policy_Id
    $DCPdisplayName=$values.display_name
    $authToken=$values.Access_token
    $TargetGroupId
    $DCPid
    $DCPdisplayName


$Assignment = Add-DeviceConfigurationPolicyAssignment -ConfigurationPolicyId $DCPid -TargetGroupId $TargetGroupId -AssignmentType Included -authToken $authToken
    Write-Host "Assigned '$AADGroup' to $DCPdisplayName" -ForegroundColor Green
    Write-Host
