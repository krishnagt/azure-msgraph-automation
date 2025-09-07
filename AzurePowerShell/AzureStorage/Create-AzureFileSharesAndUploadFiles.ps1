# NAME: azure_storage_upload.ps1
# AUTHOR: Krishna G T
# DATE: 23/03/2021
#
# KEYWORDS: Azure Powershell, get-childitem, Get Module
# file manipulation, regular expressions
#
# COMMENTS: This script creates file share and upload files to Azure storage account.
# scripts starts by installing Az.storage module for use azure powershell cmdlets for azure cloud storage.
# This script connects to Azure storage using storage account name and storage account key.
# It will create two file shares under storage account abc 1.lib (5GB) 2.docs (3 GB)
# It creates folder structure like "lib/<solution>/version/component/version/<files>" and this directory will have .zip/.exe/.msi files.
# creates folder structure for documents like "docs/<solution>/version/<files>" and this directory will have .pdf/.docx/.xml files.

#INPUT PARAMETERS : sourcePath,storageaccountname,storageaccountkey,
#solution,solutionversion,component,componentversion
#SourcePath : Directory name contains files like .zip/.msi/.exe and .pdf/.doc to upload 
#storageaccountname : Name of the storage account created on Azure Storage.
#storageaccountkey : Access Key to have permission to write to storage account.
#solution : Solution name ex: xyz
#Solution version: version of the solution ex: 1.0.0
#component : Name of particular component ex: abcd
#componentversion: version of the component ex: 2.0.1

#EXAMPLE 
#azure_storage_upload.ps1 C:\Users\azure-test-upload testaccount MJ88i/BD77g95aOk24K3DU/aWd3TUKhyK9ZV testfolder1 1.0.0 testfolder2 2.0.1


param (
        [Parameter(Mandatory = $True,Position = 1)]
        [string]$SourcePath,
        [Parameter(Mandatory = $True, Position = 2)]
        [ValidateNotNullOrEmpty()]
        [string]$StorageAccountName,
        [Parameter(Mandatory = $True, Position = 3)]
        [ValidateNotNullOrEmpty()]
        [string]$skey,
        [Parameter(Mandatory = $True, Position = 4)]
        [ValidateNotNullOrEmpty()]
        [string]$sln,
        [Parameter(Mandatory = $True, Position = 5)]
        [ValidateNotNullOrEmpty()]
        [string]$buildversion,
        [Parameter(Mandatory = $True, Position = 6)]
        [string]$cname,
        [Parameter(Mandatory = $True, Position = 7)]
        [string]$cversion,
	[Parameter(Mandatory = $True, Position = 8)]
        [string]$flag
     )
function Output 
{
param([int]$lineNumber,[string]$in)
switch ($lineNumber) 
{
    1 {Write-host "File share $in is already exists"-foregroundcolor Yellow}
    2 {Write-host "File share $in has been created"-foregroundcolor Green}
    3 {Write-Host "Directory $in is already created" -foregroundcolor Yellow}
    4 {Write-host "Directory $in has been created"-foregroundcolor Green}
    5 {Write-host "uploaded the $in file"-foregroundcolor Green}
 }
}
#Set Execution Policy to run script
Set-ExecutionPolicy RemoteSigned
# Install Azure Storage Module
$module = Get-module -name "Az.Storage" -Verbose

    If (($module.Name) -match ("Az.Storage")) 
    {
         Write-Host "Module Az.Storage is already loaded"
    }
    else {
		   Install-Module -Name Az.Storage -RequiredVersion 3.4.0
         }

#$zip = Get-ChildItem $SourcePath -Include @("*.zip","*.exe","*.msi") -Recurse
$zip = Get-ChildItem $SourcePath -Include @("*.zip","*.exe","*.msi","*.gz","*.tar") -Recurse
$pdfs = Get-ChildItem $SourcePath -Include @("*.pdf","*.doc*","*.xml") -Recurse
$cname1= $cname.TrimEnd("/")
$t=$cname1.Split('/')[-1]
$cname=$t.ToLower() -replace '\s',''
$sln=$sln.ToLower() -replace '\s',''
$outfile="output.txt"
Set-Content -Path $outfile -Value 'Download URI for uploaded files'
#Create Context
$ctx = New-AzStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $skey
#Check if FileShare docs is creates already
if((Get-AzStorageShare -Context $ctx -Name "docs" -ErrorAction SilentlyContinue)) 
    {
       output 1 "docs"
    } 
 #create New File Share docs
else {  New-AzStorageShare -Context $ctx -Name "docs" 
        Set-AzStorageShareQuota -Context $ctx -ShareName "docs" -Quota 3
        output 2 "docs"
     }
#Check if FileShare lib is creates already
if((Get-AzStorageShare -Context $ctx -Name "lib" -ErrorAction SilentlyContinue)) 
    {
       output 1 "lib"
    } 
 #create New File Share lib
else {  New-AzStorageShare -Context $ctx -Name "lib" 
        Set-AzStorageShareQuota -Context $ctx -ShareName "lib" -Quota 5
        output 2 "lib"
     }
# Check if Installer and Docs directories are exists
if((Get-AzStorageShare -Context $ctx -Name "docs" -ErrorAction SilentlyContinue | Get-AzStorageFile -Path $sln -ErrorAction SilentlyContinue))
      {
        output 3 $sln
      }
   else
   {
      ## Create directory  
      New-AzStorageDirectory -Path $sln -ShareName "docs" -Context $ctx -ErrorAction SilentlyContinue
      output 4 $sln
   } 
if((Get-AzStorageShare -Context $ctx -Name "lib" -ErrorAction SilentlyContinue | Get-AzStorageFile -Path $sln -ErrorAction SilentlyContinue))
      {
        output 3 "lib$sln"
      }
   else
   {
      ## Create directory  
      New-AzStorageDirectory -Path $sln -ShareName "lib" -Context $ctx -ErrorAction SilentlyContinue
      output 4 "lib$sln"
   }
if((Get-AzStorageShare -Context $ctx -Name "lib" -ErrorAction SilentlyContinue | Get-AzStorageFile -Path "$sln/$buildversion" -ErrorAction SilentlyContinue))
      {
        output 3 "$sln/$buildversion"
      }
   else
   {
      ## Create directory  
      New-AzStorageDirectory -Path "$sln/$buildversion" -ShareName "lib" -Context $ctx -ErrorAction SilentlyContinue
      output 4 "lib/$sln/$buildversion" 
   } 
   if (-not ([string]::IsNullOrEmpty($cname)))
    {
      #create directory for Component
      if((Get-AzStorageShare -Context $ctx -Name "lib" -ErrorAction SilentlyContinue | Get-AzStorageFile -Path "$sln/$buildversion/$cname" -ErrorAction SilentlyContinue))
      {
        output 3 "$sln/$buildversion/$cname"
      }
      else
       {
         ## Create directory  
         New-AzStorageDirectory -Path "$sln/$buildversion/$cname" -ShareName "lib" -Context $ctx -ErrorAction SilentlyContinue
         output 4 "$sln/$buildversion/$cname"
       }
  if (-not ([string]::IsNullOrEmpty($cversion)))
   {
      #create directory for Component version
      if((Get-AzStorageShare -Context $ctx -Name "lib" -ErrorAction SilentlyContinue | Get-AzStorageFile -Path "$sln/$buildversion/$cname/$cversion" -ErrorAction SilentlyContinue))
      {
        output 3 "$sln/$buildversion/$cname/$cversion"
      }
     else
      {
        ## Create directory  
        New-AzStorageDirectory -Path "$sln/$buildversion/$cname/$cversion" -ShareName "lib" -Context $ctx -ErrorAction SilentlyContinue
        output 4 "$sln/$buildversion/$cname/$cversion"
      }
      foreach ($file in $zip) 
      { 
        if($flag -eq 'true')
	     {
           Set-AzStorageFileContent -ShareName "lib"  -Context $ctx -Source $file -path "$sln/$buildversion/$cname/$cversion" -Force -ErrorAction SilentlyContinue
	     }
	   else 
	    {
	      Set-AzStorageFileContent -ShareName "lib"  -Context $ctx -Source $file -path "$sln/$buildversion/$cname/$cversion" -ErrorAction SilentlyContinue
	    }
           output 5 "$sln/$buildversion/$cname/$cversion/$file"
           $file1=$file.Name
	    $uri=New-AzStorageFileSASToken -Context $ctx -ShareName "lib" -path "$sln/$buildversion/$cname/$cversion/$file1" -Permission "r" -FullUri 
	    Add-Content -Path $outfile -Value $uri
      }
   }
 } 
 else {
        foreach ($file in $zip) 
        { 
	  if($flag -eq 'true')
	  {
           Set-AzStorageFileContent -ShareName "lib" -Context $ctx -Source $file -path "$sln/$buildversion" -Force -ErrorAction SilentlyContinue
	  }
	  else 
	  {
	    Set-AzStorageFileContent -ShareName "lib" -Context $ctx -Source $file -path "$sln/$buildversion" -ErrorAction SilentlyContinue
	  }
          output 5 "lib/$sln/$buildversion/$file"
          $file1=$file.Name
	      $uri=New-AzStorageFileSASToken -Context $ctx -ShareName "lib" -path "$sln/$buildversion/$file1" -Permission "r" -FullUri 
	      Add-Content -Path $outfile -Value $uri
        }
     } 
if((Get-AzStorageShare -Context $ctx -Name "docs" -ErrorAction SilentlyContinue | Get-AzStorageFile -Path "$sln/$buildversion" -ErrorAction SilentlyContinue))
      {
         output 3 "docs/$sln/$buildversion"
      }
   else
       {
          ## Create directory  
          New-AzStorageDirectory -Path "$sln/$buildversion" -ShareName "docs" -Context $ctx -ErrorAction SilentlyContinue
          output 4 "docs/$sln/$buildversion"
       }
  foreach ($pdf in $pdfs) 
   { 
      if($flag -eq 'true')
      {
      Set-AzStorageFileContent -ShareName "docs" -Context $ctx -Source $pdf -path "$sln/$buildversion" -Force -ErrorAction SilentlyContinue
      }
      else 
      {
        Set-AzStorageFileContent -ShareName "docs" -Context $ctx -Source $pdf -path "$sln/$buildversion" -ErrorAction SilentlyContinue
      }
      output 5 "docs/$sln/$buildversion/$pdf"
      $pdf1=$pdf.Name
	  $uri=New-AzStorageFileSASToken -Context $ctx -ShareName "docs" -path "$sln/$buildversion/$pdf1" -Permission "r" -FullUri 
	  Add-Content -Path $outfile -Value $uri
    }
  # Set execution policy back to Restricted 
  Set-ExecutionPolicy Restricted
