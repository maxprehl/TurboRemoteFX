# TurboRemoteFX

A Powershell Script which changes Group Policy and Registry entries to increase RDP (Remote Desktop) performance. (Enabling RemoteFX and Hardware, ie. GPU, H.264/AVC Encoding)

Based on the following sources:

- ["Pushing Remote FX to its limits."](https://www.reddit.com/r/sysadmin/comments/fv7d12/pushing_remote_fx_to_its_limits/?utm_source=share&utm_medium=web2x&context=3) - Reddit r/sysadmin post by u/liquidspikes
- ["How to manage Local Group Policy with Powershell"](https://gerane.github.io/powershell/Local-gpo-powershell/) - Blog post by Brandon Padgett, 2016
- [PolicyFileEditor](https://github.com/dlwyatt/PolicyFileEditor) - Github project by Dave Wyatt (dlwyatt)
- ["Optimizing RDP for casual use"](https://blog.tedd.no/2015/06/23/optimizing-rdp-for-casual-use/) - Blog post by Tedd Hansen, 2015

## Usage

Requirements:

- You need to install the PolicyFileEditor Powershell Module. To do this run:

  ```console
  PS> Install-Module -Name PolicyFileEditor -Scope CurrentUser
  ```

To make the Group Policy/Registry changes:

1. Download and extract the files.

2. Open Administrator PowerShell to that directory.

3. Then run the following:

   ```console
   PS> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process ; .\TurboRemoteFXHostGPO.ps1
   ```

4. To assert the Group Policy changes run:

   ```console
   PS> gpupdate /force
   ```

To undo the changes:

- Follow the steps above except use the `TurboRemoteFXHostGPO-inverse.ps1` script.

  ```console
  PS> Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process ; .\TurboRemoteFXHostGPO-inverse.ps1
  ```

Also recommended:

- If using NVIDIA, you should also grab their extra driver to support OpenGL over RDP
  - You will need to make an Nvidia account to download this.
  - [nvidiaopenglrdp.exe](https://developer.nvidia.com/nvidia-opengl-rdp)
  - [Khronos Group article explaining more](https://www.khronos.org/news/permalink/nvidia-provides-opengl-accelerated-remote-desktop-for-geforce-5e88fc2035e342.98417181)
- Client side changes
  - When opening an RDP connection make the settings:
    - Network Type: LAN
    - Cache Bitmaps: No

## About

The scripts simply automate making changes in Group Policy and the Registry.

### Equivalent `gpedit.msc` changes

All changes take place inside the path:

```path
Local Computer Policy
\ Computer Configuration
  \ Administrative Templates
    \ Windows Components
      \ Remote Desktop Services
        \ Remote Desktop Session Host
```

From there, the following locations take changes:

In `\Connections`

```gpedit
Select RDP Transfer Protocols = Enabled
Set Transport Type to: "Use both UDP and TCP"
```

In `\Remote Session Environment`

```gpedit
Use hardware graphics adapters for all Remote Desktop Services Sessions = Enabled
Prioritize H.264/AVC 444 graphics mode for Remote Desktop Connections = Enabled
Configure H.264/AVC Hardware encoding for Remote Desktop Connections = Enabled
    Set "Prefer AVC hardware encoding" to "Always attempt"
Configure compression for Remote FX data = Enabled
    Set RDP compression algorithm: "Do not use an RDP compression algorithm"
Configure image quality for RemoteFX Adaptive Graphics = Enabled
    Set Image Quality to "High" (lossless seemed too brutal over WAN connections.)
Enable RemoteFX encoding for RemoteFX clients designed for Windows Server 2008R2 SP1 = Enabled.
```

In `\Remote Session Environment\Remote FX for Windows Server 2008R2`

```gpedit
Configure Remote FX = Enabled
Optimize visual experience when using Remote FX = Enabled
    Set Screen capture rate (frames per second) = Highest (best quality)
    Set Screen Image Quality = Highest (best quality)
Optimize visual experience for remote desktop sessions = Enabled
    Set Visual Experience = Rich Multimedia
```

These changes correspond to the following registry entries:

```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services]
"SelectTransport"=dword:00000000
"bEnumerateHWBeforeSW"=dword:00000001
"AVC444ModePreferred"=dword:00000001
"MaxCompressionLevel"=dword:00000000
"ImageQuality"=dword:00000002
"fEnableVirtualizedGraphics"=dword:00000001
"VGOptimization_CaptureFrameRate"=dword:00000001
"VGOptimization_CompressionRatio"=dword:00000001
"VisualExperiencePolicy"=dword:00000001
```

You can check this by browsing `regedit` or using the Powershell Command:

```ps1
Get-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services"
```

### Other registry tweaks

Not all of the configurations were available with GPO, so some other registry tweaks are made in `TurboRemoteFXHost.reg`

```reg
[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services]
"AVCHardwareEncodePreferred"=dword:0
"fEnableWddmDriver"=dword:00000000
; If issues, try WDDM driver enabled.

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations]
"DWMFRAMEINTERVAL"=dword:15

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile]
"SystemResponsiveness"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\TermDD]
"FlowControlDisable"=dword:00000001
"FlowControlDisplayBandwidth"=dword:0000010
"FlowControlChannelBandwidth"=dword:0000090
"FlowControlChargePostCompression"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp]
"InteractiveDelay"=dword:00000000

[HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters]
"DisableBandwidthThrottling"=dword:00000001
"DisableLargeMtu"=dword:00000000
```
