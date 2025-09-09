# Author: GTKrishna
# Update PowerShellModules 

# PS Modules to install/update - List your modules here:
$modules = @(
    'PowershellGet' 
    'BlobTranscript'
    'AzTable'
    'Az.Storage'
    'Az.Relay'
    'Az.Websites'
    'dbatools'
        
)

function Update-Modules([string[]]$modules) {
    #Loop through each module in the list
    foreach ($module in $modules) {
        # Check if the module exists
        if (Get-Module -Name $module -ListAvailable) {
            # Get the version of the currently installed module
            $installedVersionV = (Get-Module -ListAvailable $module) | Sort-Object Version -Descending  | Select-Object Version -First 1 

            # Convert version to string
            $stringver = $installedVersionV | Select-Object @{n = 'Version'; e = { $_.Version -as [string] } }
            $installedVersionS = $stringver | Select-Object Version -ExpandProperty Version
            Write-Host "Current version $module[$installedVersionS]"
            $installedVersionString = $installedVersionS.ToString()

            # Get the version of the latest available module from gallery
            $latestVersion = (Find-Module -Name $module).Version

            # Compare the version numbers
            if ($installedVersionString -lt $latestVersion) {
                # Update the module
                Write-Host "Found latest version $module [$latestVersion], updating.."
                # Attempt to update module via Update-Module
                try {
                    Update-Module -Name $module -Force -ErrorAction Stop -Scope AllUsers
                    Write-Host "Updated $module to [$latestVersion]"
                }
                # Catch error and force install newer module
                catch {
                    Write-Host $_
                    Write-Host "Force installing newer module"
                    Install-Module -Name $module -Force -Scope AllUsers
                    Write-Host "Updated $module to [$latestVersion]"
                }
                
            }
            else {
                # Already latest installed
                Write-Host "Latest version already installed"
            
            }
        }
        else {
            # Install the module if it doesn't exist
            Write-Host "Module not found, installing $module[$latestVersion].."
            Install-Module -Name $module -Repository PSGallery -Force -AllowClobber -Scope AllUsers
            }
        }
    }
        
Update-Modules($modules)

