
#Author: GTKrishna
#This PowerShell script connects to Microsoft Graph API using client credentials, retrieves the list of detected applications from Intune-managed devices, and exports the data (including device count, app name, version, and publisher) #into a formatted Excel report using the ImportExcel module. It also includes a retry mechanism to handle Graph API rate-limiting (HTTP 429 errors).



# Install and import the necessary modules if not already installed
if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser -Force
}
Import-Module ImportExcel

# Define variables
$tenantId = ""
$clientId = ""
$clientSecret = ""
$excelFilePath = "C:\Temp\Report_DetectedApps.xlsx" # Path to save the Excel report

# Authenticate to Microsoft Graph and get the access token
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}

$response = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -ContentType "application/x-www-form-urlencoded" -Body $body
$accessToken = $response.access_token

# Function to handle API requests with retry mechanism
function Invoke-GraphRequest {
    param (
        [string]$Uri,
        [string]$Method = "Get"
    )

    $maxRetries = 5
    $retryCount = 0
    $retryDelay = 2

    while ($retryCount -lt $maxRetries) {
        try {
            return Invoke-RestMethod -Uri $Uri -Method $Method -Headers @{Authorization = "Bearer $accessToken"}
        } catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                Write-Host "Rate limit exceeded. Retrying in $retryDelay seconds..."
                Start-Sleep -Seconds $retryDelay
                $retryCount++
                $retryDelay *= 2
            } else {
                throw $_
            }
        }
    }

    throw "Max retries exceeded for request to $Uri"
}

# Get detected apps
$detectedApps = Invoke-GraphRequest -Uri "https://graph.microsoft.com/v1.0/deviceManagement/detectedApps"

# Initialize an array to store app data
$appData = @()

# Process the detected apps data
foreach ($app in $detectedApps.value) {
    $appDetails = [PSCustomObject]@{
        DeviceCount   = $app.deviceCount
        AppName    = $app.displayName
        Version    = $app.version
        Publisher  = $app.publisher
    }
    $appData += $appDetails
}

# Export the data to an Excel file
$appData | Export-Excel -Path $excelFilePath -AutoSize -Title "Detected Apps Report"

Write-Host "Report generated successfully at $excelFilePath"
