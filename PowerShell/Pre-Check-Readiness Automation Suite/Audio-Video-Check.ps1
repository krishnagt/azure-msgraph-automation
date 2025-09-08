<#

 File: AudioVideo.PS1
 Description: This script fetches and validates Audio/Video related pre-requsites parameters
 Date: 13/19/2021
#>
		
## Calling A/V Functions


[void][Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
Function Write-DisplayLog()
{
    param
    (
        [Parameter(Mandatory=$true)] [string] $LogLevel,
        [Parameter(Mandatory=$true)] [string] $Message,
        [Parameter(Mandatory=$false)] [bool] $NoNewline = $false
    )
    
    switch($LogLevel){
       Info {$Color = "Yellow" ; break}
       Success {$Color = "Green"; break}
       Error {$Color = "Red"; break}
    }
       
    if($NoNewline)
    {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $Message -ForegroundColor $Color
    }
}

 ## Install Module Audio Device



	If (! (Get-Module -Name "AudioDeviceCmdlets" -ListAvailable)) 
    {
		$url='SASFORAUDIODRIVERS'
		$location = ($profile | split-path)+ "\Modules\AudioDeviceCmdlets\AudioDeviceCmdlets.dll"
		New-Item "$($profile | split-path)\Modules\AudioDeviceCmdlets" -Type directory -Force
 
		[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
		(New-Object System.Net.WebClient).DownloadFile($url, $location)
	}

    If(! (Get-Module -Name "AudioDeviceCmdlets"))
	{
		Get-module -Name "AudioDeviceCmdlets" -ListAvailable | Sort-Object Version | select -last 1 | Import-Module
	}


## Check Audio Device Driver

	$sound_info = Get-WmiObject -class Win32_SoundDevice
	foreach ($zsound_info in $sound_info)
	{
		$sound_status=$sound_info.statusinfo
		$audio_device=$zsound_info.ProductName

		if ($sound_status -eq "3")
		{
			Write-DisplayLog -LogLevel Success -Message "Audio Device $audio_device state is Enabled"
			$AudioDriverstatus="Pass"
			$AudioDrivervalue="$audio_device is Enabled"
		
		} elseif ($sound_status -eq "4") {
		
			Write-DisplayLog -LogLevel Error -Message "Audio Device $audio_device state is Disabled"
			$AudioDriverstatus="Fail"
			$AudioDriverstatusComments="$audio_device is disabled"
		
		} elseif ($sound_status -eq "5") {
		
			Write-DisplayLog -LogLevel Error -Message "Sorry can't access sound device property."
			$AudioDriverstatus="Fail"
			$AudioDriverstatusComments="$audio_device can not be accessed at this moment"
		} else {
		
			Write-DisplayLog -LogLevel Info "Check for further errors if sound device is not working."
			$AudioDriverstatus="Fail"
			$AudioDriverstatusComments="$audio_device Something went wrong"
		
		}    
	}
	
	$AudioVideoHash = @()
	$hash = New-Object PSObject -property @{Parameters="Audio Device Driver";Value="$AudioDrivervalue";Status="$AudioDriverstatus";Comments="$AudioDriverstatusComments"}
	$AudioVideoHash += $hash
	
## Check Audio Output


   #Write-DisplayLog -LogLevel Info "******* Checking Audio Output ********"
   
   # Set "Device as Default Playback and Recording Device in Windows" 

	if ((Get-Module -Name "AudioDeviceCmdlets") ) 
	{
		$device=Get-AudioDevice -List | where Type -like "Playback" | where name -like "*Speakers (Real*"  | Set-AudioDevice 
		$audio_output= $device.name
		Write-DisplayLog -LogLevel Info "Audio Output set to $audio_output "
		[system.console]::beep(1000,500)
		
		if($audio_output -like "*Speakers (Real*")
		{
			$AudioOutput="Pass"
            $AudioOutputvalue="Audio output device set to $audio_output"
		} else {
			$AudioOutput="Fail" 
			$AudioOutputComments = "Audio output not set to Speakers" 
		}
		 
	}
	
	$hash = New-Object PSObject -property @{Parameters="Audio Output";Value="$AudioOutputvalue";Status="$AudioOutput";Comments="$AudioOutputComments"}
	$AudioVideoHash += $hash

### Check record and Playback
#[Microsoft.VisualBasic.Interaction]::MsgBox("Please complete your Audio test in 30 seconds")
	$rec=Get-AudioDevice -Recording
	$ad=$rec.Name
	$recdevice=$ad
    $vc=Get-StartApps  -Name *Voice Recorder*
    if($vc -eq $null)
    {
      $RecComments = "Voice Recorder does not exist"
      $Rec="FAIL"
    }

    else
    {
    explorer.exe shell:appsFolder\Microsoft.WindowsSoundRecorder_8wekyb3d8bbwe!App
    sleep 10
	#sleep 2
    $check=[Microsoft.VisualBasic.Interaction]::MsgBox("Were you able to record and playback?","YesNo,SystemModal,Information,DefaultButton1", "Audio Test")
	switch($check) 
	{
		'Yes' { $Rec="Pass" 
		$Recvalue= "Recording Device is $ad " }
		'No' { $Rec="Fail" 
		$RecComments="Recording and Playback is not working as per User input" }
    }
    Stop-Process -Name SoundRec -erroraction 'silentlycontinue'
	}
	$hash = New-Object PSObject -property @{Parameters="Recording and Playback";Value="$Recvalue";Status="$Rec";Comments="$RecComments"}
	$AudioVideoHash += $hash
	
##### Video Check

	$video = Get-CimInstance Win32_PnPEntity | where caption -match 'camera'
	$status=$video.Status
	$details= $video.Name
	if($details -like "*camera*")
	{
		$VideoDriver="Pass"
        $VideoDrivervalue=" $details is Enabled"
	} else {
		$VideoDriver="Fail" 
		$VideoDriverComments="Can not find Camera in system" 
    }
	
		
	$hash = New-Object PSObject -property @{Parameters="Video Driver";Value="$VideoDrivervalue";Status="$VideoDriver";Comments="$VideoDriverComments"}
	$AudioVideoHash += $hash
	
	Write-DisplayLog -LogLevel Info "Installed camera : $details state is $status"
	
	
	if($status -ne 'OK')
	{
		## Enable Camera 
		Enable-PnpDevice -InstanceId (Get-PnpDevice -FriendlyName *camera* -Class Camera -Status Error).InstanceId 
		Write-DisplayLog -LogLevel Success " Camera has been Enabled"
	} else {
		Write-DisplayLog -LogLevel Info "Starting Camera.........."
		sleep 2
		#$userinput=[Microsoft.VisualBasic.Interaction]::MsgBox("Please complete your Camera test in 30 seconds")
        $vc=Get-StartApps -Name *Camera*
        if($vc -eq $null)
        {
         $cameracheckComments = "Camera does not exist"
         $cameracheck="FAIL"
        }

    else
    {
		start microsoft.windows.camera:
		sleep 10
		#sleep 2
		$checkc=[Microsoft.VisualBasic.Interaction]::MsgBox("Were you able to check camera?","YesNo,SystemModal,Information,DefaultButton1", "Camera Test")
		switch($checkc)
		{
			'Yes' { $cameracheck="Pass" }
			'No' { $cameracheck="Fail" 
			$cameracheckComments = "Camera is not tested/ not working" }
		} 
		
		Stop-Process -Name WindowsCamera -erroraction 'silentlycontinue'
        }
    }

	$hash = New-Object PSObject -property @{Parameters="Camera";Value="Camera check by User";Status="$cameracheck";Comments="$cameracheckComments"}
	$AudioVideoHash += $hash

### External Camera Check 

$Ecam=Get-PnpDevice -PresentOnly -Class Camera,image -Status OK  | Where-Object { $_. InstanceId -match '^USB' } 
$present=$Ecam.FriendlyName
$present
if($present -ne $null)
{
  
		$Ecamstatus="Pass"
        $Ecamvalue=" $present"
        
	} else {
		$Ecamstatus="Fail" 
     
		$EcamstatusComments="Can not find External Camera in system" 
    }

	$hash = New-Object PSObject -property @{Parameters="External USB Input camera";Value="$Ecamvalue";Status="$Ecamstatus";Comments="$EcamstatusComments"}
	$AudioVideoHash += $hash
  
  write-host -ForegroundColor Green "Audio/Vedio Validation has been Completed"

	
