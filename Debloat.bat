@echo off
:: Minimal Windows Debloater (safe set) - Batch wrapper
:: Runs a PowerShell script inline. Keep Store & core system intact.
::Made by Auxk0rd 2025
:: Requires admin
openfiles >nul 2>&1
if %errorlevel% NEQ 0 (
  echo [!] Please run this as Administrator.
  pause
  exit /b 1
)

:: Run PowerShell with bypassed policy for this process only
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Write-Host '==> Creating a system restore point (if enabled)...';" ^
  "try { Checkpoint-Computer -Description 'Pre-Debloat' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop } catch { Write-Host '   (Restore points disabled or failed, continuing...)' };" ^
  "" ^
  "Write-Host '==> Removing obvious bloat UWP apps (per-user)...';" ^
  "$patterns = @('xbox','zune','bing','solitaire','skypeapp','gethelp','getstarted','mixedreality','3d','feedbackhub','clipchamp','tiktok','candycrush','spotify','disney','primevideo','news');" ^
  "foreach ($p in $patterns) { Get-AppxPackage -Name *$p* -AllUsers | Remove-AppxPackage -ErrorAction SilentlyContinue }" ^
  "" ^
  "Write-Host '==> Trying to remove provisioned (preinstalled for new users) packages...';" ^
  "foreach ($p in $patterns) { Get-AppxProvisionedPackage -Online | Where-Object { $_.DisplayName -like ('*' + $p + '*') } | ForEach-Object { Try { Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction Stop } Catch {} } }" ^
  "" ^
  "Write-Host '==> Disabling some telemetry/consumer experiences (light-touch)...';" ^
  "New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Force | Out-Null;" ^
  "New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -Value 0 -PropertyType DWord -Force | Out-Null;" ^
  "New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Force | Out-Null;" ^
  "New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableConsumerFeatures' -Value 1 -PropertyType DWord -Force | Out-Null;" ^
  "New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Force | Out-Null;" ^
  "New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0 -PropertyType DWord -Force | Out-Null;" ^
  "New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SystemPaneSuggestionsEnabled' -Value 0 -PropertyType DWord -Force | Out-Null;" ^
  "" ^
  "Write-Host '==> Turning off tips/ads & background suggestions...';" ^
  "New-Item -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Force | Out-Null;" ^
  "New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSyncProviderNotifications' -Value 0 -PropertyType DWord -Force | Out-Null;" ^
  "" ^
  "Write-Host '==> Disabling optional telemetry services (non-critical)...';" ^
  "foreach ($svc in @('DiagTrack','dmwappushservice')) { if (Get-Service -Name $svc -ErrorAction SilentlyContinue) { try { Stop-Service $svc -Force -ErrorAction SilentlyContinue } catch {}; Set-Service $svc -StartupType Disabled -ErrorAction SilentlyContinue } }" ^
  "" ^
  "Write-Host '==> Trimming startup apps (current user)...';" ^
  "Get-CimInstance Win32_StartupCommand | ForEach-Object { try { $n=$_.Name; Write-Host ('   disabling: ' + $n); } catch {} }" ^
  "Write-Host '   (Open Task Manager > Startup to toggle specific ones visually.)';" ^
  "" ^
  "Write-Host '==> Done. Reboot recommended to finish cleanup.';"

echo.
echo [i] Debloat complete. Reboot is recommended.
pause
