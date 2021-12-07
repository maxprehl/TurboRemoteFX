# TurboRemoteFXHostGPO-inverse
#
# Based on:
# https://www.reddit.com/r/sysadmin/comments/fv7d12/pushing_remote_fx_to_its_limits/?utm_source=share&utm_medium=web2x&context=3
# https://gerane.github.io/powershell/Local-gpo-powershell/
# https://github.com/dlwyatt/PolicyFileEditor

# TO RUN:
# 1. Install PolicyFileEditor (not Microsoft)
    # PS> Install-Module -Name PolicyFileEditor -Scope CurrentUser
# 2. Cd to where script is
    # PS> cd $HOME\Downloads\TurboRemoteFX
# 3. Run script from  with executionpolicy bypass
    # PS> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process ; ./TurboRemoteFXHostGPO-inverse
# 4. Force Update Group Policy
    # PS> gpupdate /force

Import-Module PolicyFileEditor

$MachinePath = "$env:windir\system32\GroupPolicy\Machine\registry.pol"
$UserPath = "$env:windir\system32\GroupPolicy\User\registry.pol"
$Xml = ".\TurboRemoteFXHostGPO.xml"
$Reg = ".\TurboRemoteFXHost-inverse.reg"
$Err = ''

if (-not ((Test-Path $Xml) -or (Test-Path $Reg))) {
    Write-Error "Script must be run from same directory as $Xml and $Reg"
    Exit 1
}

try {
    Import-Clixml -Path $Xml | Select-Object Key,ValueName | Remove-PolicyFileEntry -Path $MachinePath
    Write-Host -ForegroundColor Green `
        "SUCCESS: Local Group Policy settings have been unset."
} catch {
    Write-Host -ForegroundColor Magenta `
        "ERROR: The following error occurred:"
    Write-Host -ForegroundColor Red $_
    Write-Host -ForegroundColor Red $_.ScriptStackTrace
    Write-Host -ForegroundColor Magenta `
        "FAILRE: Local Group Policy settings have not been changed."
    $Err = $_
}

Write-Host -ForegroundColor Cyan "Your Local Group Policy now contains:"
Get-PolicyFileEntry -Path $MachinePath -All | Format-Table

Write-Host -ForegroundColor Cyan "The corresponding Registry path contains:"
Get-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" | Format-Table

if ($Err) {Exit 2}

$title = "Unset Registry Entries"
$message = "Do you also want to unset the registry entries (as defined in $Reg?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Runs $Reg, unsetting the registry entries."
$no = New-Object System.Management.Automation.Host.ChoiceDescription "&No", `
    "Skips running $Reg, leaving the registry unchanged."
$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0)

switch ($result)
    {
        0 {Write-Host "Running $Reg."}
        1 {Write-Host "Skipped $Reg."}
    }

if ($result -eq 0) {
    reg.exe import $Reg
    Write-Host -ForegroundColor Cyan `
        "SUCCESS: The target Registry path now contains: "
    Get-Item -Path "Registry::HKEY_LOCAL_MACHINE\Software\Policies\Microsoft\Windows NT\Terminal Services" | Format-Table
}

# Sets the following gpedit.msc Controls to "Not Configured":

# Computer Configuration > Administrative Templates
# Windows Components\Remote Desktop Services\Remote Desktop Session Host\Connections

    # Select RDP Transfer Protocols = Enabled
    # Set Transport Type to: "Use both UDP and TCP"

# Computer Configuration > Administrative Templates
# Windows Components\Remote Desktop Services\Remote Desktop Session Host\Remote Session Enviorment

    # Use hardware graphics adapters for all Remote Desktop Services Sessions = Enabled
    # Prioritize H.264/AVC 444 graphics mode for Remote Desktop Connections = Enabled
    # Configure H.264/AVC Hardware encoding for Remote Desktop Connections = Enabled
        # Set "Prefer AVC hardware encoding" to "Always attempt"
    # Configure compression for Remote FX data = Enabled
        # Set RDP compression algorithem: "Do not use an RDP compression algorithm"
    # Configure image quality for RemoteFX Adaptive Graphics = Enabled
        # Set Image Quality to "High" (lossless seemed too brutal over WAN connections.)
    # Enable RemoteFX encoding for RemoteFX clients designed for Windows Server 2008R2 SP1 = Enabled.

# Computer Configuration > Administrative Templates
# Windows Components\Remote Desktop Services\Remote Desktop Session Host\Remote Session Enviorment\Remote FX for Windows Server 2008R2

    # Configure Remote FX = Enabled
    # Optimize visual experience when using Remote FX = Enabled
        # Set Screen capture rate (frames per second) = Highest (best quality)
        # Set Screen Image Quality = Highest (best quality)
    # Optimize visual experience for remote desktop sessions = Enabled
        # Set Visual Experience = Rich Multimedia
