




param (
    [Parameter (Mandatory = $false)]
    [object] $WebHookData
)
if(-Not $WebHookData.RequestBody )
{
    $WebHookData=(ConvertFrom-Json -InputObject $WebHookData)
     $WebhookName     =     $WebHookData.WebhookName
    $WebhookHeaders  =     $WebHookData.RequestHeader
    $WebhookBody     =    $WebHookData.RequestBody
    #write-output "test $WebhookName $WebhookHeaders $WebhookBody "
}
Else {
       Write-Error -Message 'Runbook was not started from Webhook' -ErrorAction stop
      }
$jsonObj = (ConvertFrom-Json -InputObject $WebHookData.RequestBody)
$columns = $jsonObj.data.SearchResult.tables[0].columns
$resultList = @()
Foreach ($i in $jsonObj.data.SearchResult.tables[0].rows)
 {
  [hashtable]$row = @{}
  for( $j=0 ; $j -lt $columns.Length ; $j++) 
  {
  $columnName = $columns[$j].name
  $value = $i[$j]
  $row[$columnName] =  $value
  }
  $resultList += $row
 }
[hashtable]$hash_body = @{}
$hash_body["query"] = 'mutation insert_log_analytics($objects: [log_analytics_insert_input!]!) {insert_log_analytics(objects: $objects) {returning {ID}}}'
$hash_body["operationName"] = "insert_rocc_log_analytics"
[hashtable]$arry_objects = @{}
$arry_objects.Add("objects", $resultList)
$hash_body["variables"] = $arry_objects
$bodyJson = ConvertTo-Json $hash_body -Depth 3
$bodyJson
Write-Verbose -Message 'Connecting to Azure'
$ConnectionName = 'AzureRunAsConnection'
try
{
    # Get the connection properties
    $ServicePrincipalConnection = Get-AutomationConnection -Name $ConnectionName 
$ServicePrincipalConnection    
 
    'Log in to Azure...'
    $null = Connect-AzAccount `
        -ServicePrincipal `
        -TenantId $ServicePrincipalConnection.TenantId `
        -ApplicationId $ServicePrincipalConnection.ApplicationId `
        -CertificateThumbprint $ServicePrincipalConnection.CertificateThumbprint 
}
catch 
{
    if (!$ServicePrincipalConnection)
    {
 
        $ErrorMessage = "Connection $ConnectionName not found."
        throw $ErrorMessage
    }
    else
    {
 
        Write-Error -Message $_.Exception.Message
        throw $_.Exception
    }
}
#######################################
$VaultName = "audittestkayvault"
$SecretName1 = "username"
$SecretName2 = "password"
# Retrieve value from Key Vault
$username = (Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName1).SecretValueText
$password = (Get-AzKeyVaultSecret -VaultName $VaultName -Name $SecretName2).SecretValueText
[hashtable]$hash_body = @{}
$hash_body["loginUserKey"] = "username"
$hash_body["loginUserName"] = "password"
$body_access = ConvertTo-Json $hash_body -Depth 3
$Uri = ''
$response = Invoke-RestMethod -Uri $Uri -Method POST -Body $body_access -ContentType 'application/json' 
write-output $response
$convertjson = ConvertTo-Json $response
$jsonObj = ConvertFrom-Json $convertjson
$access_token = $jsonObj.accessToken
#$orgid = $jsonObj.orgId
#$orgid1= @{'Org-Id'= "$orgid"} | ConvertTo-Json
#########################################
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Authorization", "$access_token")
$headers.Add("org_ctxt_header", '{"Org-Id": ""}') 
#write-output $headers
$bodyJson1 = ConvertFrom-Json $bodyJson
Foreach ($i in $bodyJson1.variables.objects)
 {
$dateTime = $i.TimeGenerated
write-output $dateTime
$userId = $i.TenantId
$source = $i.Source
$sourceType = $i.Type
$componentName = $i.Computer
$person= $i.ParameterXml
$personType = [xml]$person
$tc=($personType.Param).Trim() -replace '\s+', ' '
$tenant = $i.TenantId
$code = $i.EventID
$value = $i.EventLevelName
$site_name = $i.SourceSystem
$eventtype = $i.EventLevelName
$body_audit = @"
{
    "eventType": "$eventtype",
    "eventSubType": "Audit",
    "action": "C",
    "dateTime": "$dateTime",
    "outcome": "0",
    "userId": "$userId",
    "source": "Audit logs from $source",
    "sourceType": "$tc",
    "extension": {
        "applicationVersion": "1",
        "componentName": "$componentName Emerald Application",
        "tenant": "$tenant"
    },
    "object": [{
       "code": "$code",
        "value": "$value"
    }, {
        "code": "",
        "value": ""
    }]
}
"@
#Replace windows CRLF to Unix LF
$lines = $body_audit.Split([Environment]::NewLine)
foreach ($line in $lines)
    {  
        $body+=$line.Replace("`r`n",[System.Environment]::NewLine)
    }
$audit_uri = ''
$audit_push = Invoke-RestMethod -Uri $audit_uri -Method POST -Headers $headers -Body $body -ContentType 'application/json;charset=utf-8'
$body
$audit_push
}
