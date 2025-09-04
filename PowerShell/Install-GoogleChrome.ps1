################################
Function Enable-GoogleChromeServices() 
{
    $status = Get-WMIObject win32_service -filter "name='gupdate'" -computer "."
                
    if ($status.StartMode -eq "Disabled")
    {
        Set-Service -Name gupdate -StartupType Manual
    }

    $status = Get-WMIObject win32_service -filter "name='gupdatem'" -computer "."
    if ($status.StartMode -eq "Disabled")
    {
        Set-Service -Name gupdatem -StartupType Manual
    }
}

Function Install-GoogleChrome() 
{
    Enable-GoogleChromeServices
    #Chrome Installation 
    Write-DisplayLog -LogLevel Info -Message "######################################" -nonewline $true
    Write-DisplayLog -LogLevel Info -Message " Starting Chrome Installation " -nonewline $true
    Write-DisplayLog -LogLevel Info -Message "##########################################" 
    Write-Host "" 
    
    Write-ProgressHelper -status 'Starting Google Chrome Installation..' -Message ' ' -percent 10
    #Read Config file
    $Path=".\config\config.txt"
    $values=Get-Content $Path | Out-String | ConvertFrom-StringData
    $SourceFile=$values.Chrome_DOWNLOAD_URL
    $Application = $SourceFile.Split("/")[$SourceFile.Split("/").Count - 1]
    Write-DisplayLog -LogLevel Info -Message "Installing Chrome..."
    Write-Host ""
    $TargetFile= Join-Path $PSScriptRoot "..\..\$SourceFile"
    $TargetFile=Resolve-Path $TargetFile 
    # Install Chrome
    $ChromeMSI = """$TargetFile"""
    try
    {
	$ExitCode = (Start-Process -filepath msiexec -argumentlist "/i $ChromeMSI /qn /norestart" -Wait -PassThru).ExitCode
    if ($ExitCode -eq 0) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name 'AutofillAddressEnabled' -Value '0' -Type DWord
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Google\Chrome" -Name 'ImportAutofillFormData' -Value '0' -Type DWord
        Write-DisplayLog -LogLevel Success -Message 'Google Chrome Installation success!' 
        Write-ProgressHelper -status 'Google Chrome Installation success!' -Message ' ' -percent 10
        Start-Sleep -Seconds 1
        successcount
    } else {
        Write-DisplayLog -LogLevel error -Message "failed. There was a problem installing Google Chrome. MsiExec returned exit code $ExitCode." 
        Write-ProgressHelper -status 'Google Chrome Installation Failed!' -Message ' ' -percent 10
        Start-Sleep -Seconds 1
    }
    }
    catch { Write-Warning $_.Exception.Message }

}
