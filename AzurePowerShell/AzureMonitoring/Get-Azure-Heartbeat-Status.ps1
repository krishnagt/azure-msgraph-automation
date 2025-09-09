<#
###############################################################################
# 
# Author: GTKrishna
# File: Get-Azure-Heartbeat-Status.ps1
#
# Description:
# This PowerShell script connects to an Azure Log Analytics workspace and runs
# a KQL query against the Heartbeat table to monitor VM health status.
#
# Key Functions:
# - Connects to Azure using Connect-AzAccount.
# - Targets a specific Log Analytics workspace by resource group and name.
# - Executes a KQL query to:
#     • Retrieve the latest heartbeat from each VM within the last 30 minutes.
#     • Determine whether the VM is 'Healthy' or 'Unhealthy' based on heartbeat age.
#     • Calculate how long ago the last heartbeat was seen (seconds/minutes/hours/days).
#     • Build a simple trend of heartbeat activity for VMs containing "APHI" in their name.
#     • Join and enrich results with OS, environment, and resource details.
# - Filters for unhealthy machines and orders results by state and average trend.
# - Outputs the final results with key fields (PipelineName, Computer, Version).
#
# Use Case:
# Enables administrators to quickly identify VMs with missing or delayed heartbeats,
# track heartbeat patterns, and proactively respond to unhealthy systems in Azure.
#
#
# Date: 15-10-2024
###############################################################################
#>


Connect-AzAccount 
 $Workspace=Get-AzOperationalInsightsWorkspace -ResourceGroupName RG1 -Name RG1
 $kqlQuery = @"
  Heartbeat  
| where TimeGenerated > ago(30m)  
| summarize LastHeartbeat = max(TimeGenerated) by Computer  
| extend State = iff(LastHeartbeat < ago(10m), 'Unhealthy', 'Healthy')  | extend TimeFromNow = now() - LastHeartbeat  
| extend ["TimeAgo"] = strcat(case(TimeFromNow < 2m, strcat(toint(TimeFromNow / 1m), ' seconds'), TimeFromNow < 2h, strcat(toint(TimeFromNow / 1m), ' minutes'), TimeFromNow < 2d, strcat(toint(TimeFromNow / 1h), ' hours'), strcat(toint(TimeFromNow / 1d), ' days')), ' ago')  
| join (  
    Heartbeat  
    | where TimeGenerated > ago(30m)  
    | extend Packed = pack_all()  
)  
on Computer  
| where TimeGenerated == LastHeartbeat  
| join (  
    Heartbeat  
    | where TimeGenerated > ago(30m)  
    | where Computer contains "APHI"  
    | make-series InternalTrend=iff(count() > 0, 1, 0) default = 0 on TimeGenerated from ago(30m) to now() step 30m by Computer  
    | extend Trend=array_slice(InternalTrend, array_length(InternalTrend) - 30, array_length(InternalTrend) - 1)  
    | extend (s_min, s_minId, s_max, s_maxId, s_avg, s_var, s_stdev) = series_stats(Trend)  
    | project Computer, Trend, s_avg  
)  
 on Computer  
| order by State, s_avg asc, TimeAgo  
| where State contains "unhealthy" 
| project  
    ["_ComputerName_"] = Computer,  
    ["Computer"]=strcat('🖥️ ', Computer),  
    State,  
    ["Environment"] = iff(ComputerEnvironment == "Azure", ComputerEnvironment, Category),  
    ["OS"]=iff(isempty(OSName), OSType, OSName),  
    ["Azure Resource"]=ResourceId,  
    Version,  
    ["Time"]=strcat('🕒 ', TimeAgo),  
    ["Heartbeat Trend"]=Trend,  
    ["Details"]=Packed
"@
 $QueryResults = Invoke-AzOperationalInsightsQuery -Workspace $Workspace -Query $kqlQuery
 $QueryResults.Results | Select-Object -Property PipelineName, Computer,Version

