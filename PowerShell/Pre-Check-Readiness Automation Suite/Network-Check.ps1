<#
File: Network.PS1
 Description: This script fetches and validates Network related pre-requsites parameters
 Date: 13/19/2021
#>

# System Network Speed Pre Check

# Ethernet or Wireless network detection and check

$Ethernet = get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" |select netconnectionid, name | where {$_ -match "Ethernet"}

$Wifi = get-wmiobject win32_networkadapter -filter "netconnectionstatus = 2" |select netconnectionid, name | where {($_ -match "Wi-Fi") -or ($_ -match "Wireless")} 


	If ($Ethernet){
		$EthernetStatus = "Pass"
		$EthernetType = $Ethernet.Name
	} Else {
		$EthernetStatus = "Fail"
		$EthernetComments = "Ethernet Network not found"
	}
	$NetworkHash = @()	
	$Hash = New-Object PSObject -property @{Parameters="Ethernet Card Status";Value="$EthernetType";Status="$EthernetStatus";Comments="$EthernetComments"}
	$NetworkHash += $Hash

	If ($Wifi) {
		$WifiStatus = "Fail"
		$WifiType = $Wifi.Name
		$WifiComments = "Wireless Network is being Used"
		
	} Else {
		$WifiStatus = "Pass"
		$WifiType = "Wireless Network not in use as expected"
	}	

	$Hash = New-Object PSObject -property @{Parameters="Wireless Card Status";Value="$WifiType";Status="$WifiStatus";Comments="$WifiComments"}
	$NetworkHash += $Hash	


# Check if System has Static or DHCP IP

	$IPAssignType = (Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE).DHCPEnabled
	$IPStatus = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -Filter IPEnabled=TRUE

	IF ($IPStatus)
		{
			If ($IPAssignType){
				$IPAssignStatus = "Pass"
				$IPAssignValue = "DHCP Enabled IP"
			} Else {
				$IPAssignStatus = "Pass"
				$IPAssignValue = "Static IP Assigned"
			}
		}
	Else
		{
			$IPAssignStatus = "Fail"
			$IPAssignValue = "No IP Found"
			$IPAssignComments = "No IP Found"
		}			
	
	$Hash = New-Object PSObject -property @{Parameters="IP Assignment";Value="$IPAssignValue";Status="$IPAssignStatus";Comments="$IPAssignComments"}
	$NetworkHash += $Hash

# IP Address

	$EthernetIPStatus = Get-NetIPAddress -AddressFamily IPV4 | Where-Object { $_.InterfaceAlias -match "Ethernet"}
	$WifiIPStatus = Get-NetIPAddress -AddressFamily IPV4 | Where-Object { $_.InterfaceAlias -match "Wi-Fi"}
	If ($EthernetIPStatus)
	{
		$TabIPAddressStatus = "Pass"
		$TabIPAddress = (Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias Ethernet*).IPAddress | Select -First 1
		$TabIPAddressComments = ""
	}
	ElseIf ($WifiIPStatus)
	{
		$TabIPAddressStatus = "Fail"
		$TabIPAddress = (Get-NetIPAddress -AddressFamily IPV4 -InterfaceAlias Wi-Fi).IPAddress
		$TabIPAddressComments = "System is using the Wi-Fi assigned IP address"
	}
	Else
	{
		$TabIPAddress = ""
		$TabIPAddressStatus = "Fail"
		$TabIPAddressComments = "No IP has been assigned"
	}
	
	$Hash = New-Object PSObject -property @{Parameters="IP Address";Value="$TabIPAddress";Status="$TabIPAddressStatus";Comments="$TabIPAddressComments"}
	$NetworkHash += $Hash
	
# LAN Bandwidth

	$TabletNetSpeed = (Get-NetAdapter -Name * -Physical | Where-Object {$_.Status -eq "Up"}).LinkSpeed 
	$TabletNetSpeedNum = [int]($TabletNetSpeed  | Foreach {($_ -split '\s+',4)[0..2]} | Select -First 1)
	
	IF ($TabletNetSpeed | where {$_ -match "Gbps"})
	{
		$NetSpdStatus = "Pass"
	}
	Else 
	{
		IF($TabletNetSpeedNum -ge 125)
		{
			$NetSpdStatus = "Pass"
		} 
		Else
		{
			$NetSpdStatus = "Fail"
			$NetSpdStatusComments = "LAN Bandwidth is less than 125 MBps"
		}
	}

	
	$Hash = New-Object PSObject -property @{Parameters="LAN Bandwidth";Value="$TabletNetSpeed";Status="$NetSpdStatus";Comments="$NetSpdStatusComments"}
	$NetworkHash += $Hash
	
# Internet 	Bandwidth

# UnZip Function

	Add-Type -AssemblyName System.IO.Compression.FileSystem
	function Unzip
	{
		param([string]$zipfile, [string]$outpath)
		[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
	}

# Old files clean up

	Remove-Item C:\Temp\ookla-speedtest* -Force -ErrorAction SilentlyContinue 
	Remove-Item C:\Temp\speedtest* -Force -ErrorAction SilentlyContinue 

# Download the Speedtest.exe to test the download speedtest

	$SpeedTestSource = 'SASURLFOROOKLA'
	$SpeedTestDestination = 'C:\temp\ookla-speedtest-1.0.0-win64.zip'
    try {
	Invoke-WebRequest -Uri $SpeedTestSource -OutFile $SpeedTestDestination
  
	If (echo $?)
	{
		Unzip "$SpeedTestDestination" "C:\Temp\"
	
		IF ("C:\Temp\speedtest.exe")
		{
			CD C:\temp
			$BandWidth = (.\speedtest.exe --accept-license | where {$_ -match "Download:"} |  %{$_.Split(':')[1];} | %{$_.Split('.')[0];} | select -first 1).Trim()

			If ($BandWidth -ge 20)
			{
				$BroadbandStatus = "Pass"
				$BroadbandValue = "Internet Download Speed : $BandWidth Mbps"
			} Else {
				
				$BroadbandStatus = "Fail"
				$BroadbandComments = "Internet Download Speed : $BandWidth Mbps, lesser than recommened 20 Mbps"
			}
			
		} Else {
			
			$BroadbandStatus = "Fail"
			$BroadbandComments = "Unable to extract Speedtest api and perform the Internet Speed Test"
		
		}
	} Else {
		
		$BroadbandStatus = "Fail"
		$BroadbandComments = "Unable to download Speedtest api and perform the Internet Speed Test"
	}
}
catch { write-host "Unable to run speedtest" } 

# Clean of Speed test api

	Remove-Item C:\Temp\ookla-speedtest* -Force -ErrorAction SilentlyContinue 
	Remove-Item C:\Temp\speedtest* -Force -ErrorAction SilentlyContinue

	$Hash = New-Object PSObject -property @{Parameters="Internet Bandwidth";Value="$BroadbandValue";Status="$BroadbandStatus";Comments="$BroadbandComments"}
	$NetworkHash += $Hash

write-host -ForegroundColor Green "Network Validation has been Completed"
	
