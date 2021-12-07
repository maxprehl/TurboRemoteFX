# TurboRemoteFXHostGPO

Import-Module PolicyFileEditor

$MachinePath = "$env:windir\system32\GroupPolicy\Machine\registry.pol"
$UserPath = "$env:windir\system32\GroupPolicy\User\registry.pol"
$Xml = ".\TurboRemoteFXHostGPO.xml"
$Reg = ".\TurboRemoteFXHost.reg"
$Err = ''

if (-not (Test-Path $Xml)) {
    Write-Error "Script must be run from same directory as $Xml and $Reg"
    Exit 1
}

try {
    Import-Clixml -Path $Xml | Set-PolicyFileEntry -Path $MachinePath
    Write-Host -ForegroundColor Green `
        "SUCCESS: Local Group Policy settings have been set."
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

$title = "Set Registry Entries"
$message = "Do you also want to set the registry entries (as defined in $Reg?"
$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", `
    "Runs $Reg, setting the registry entries."
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
