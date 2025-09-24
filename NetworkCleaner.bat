@echo off
setlocal EnableExtensions EnableDelayedExpansion
title Network Refresh Utility
::Made by Auxk0rd 2025
:: --- Self-elevate to Admin ---
openfiles >nul 2>&1
if not %errorlevel%==0 (
  echo [!] Admin rights required. Prompting for elevation...
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
  exit /b
)

echo.
echo ============================================
echo   Windows Network Refresh (Safe Defaults)
echo ============================================
echo.

echo [1/7] Releasing DHCP lease...
ipconfig /release
echo.

echo [2/7] Flushing DNS resolver cache...
ipconfig /flushdns
echo.

echo [3/7] Renewing DHCP lease...
ipconfig /renew
echo.

echo [4/7] Re-registering DNS (safe on home/domain)...
ipconfig /registerdns
echo.

echo [5/7] Clearing ARP cache...
netsh interface ip delete arpcache
echo.

echo [6/7] Resetting Winsock (socket catalog)...
netsh winsock reset
echo.

echo [7/7] Resetting TCP/IP stack (log: resetlog.txt)...
netsh int ip reset resetlog.txt
echo.

echo [i] Cleanup complete. A reboot is recommended to apply netsh resets.
choice /M "Reboot now"
if errorlevel 2 goto :done
shutdown /r /t 0
goto :eof

:done
echo Okay, not rebooting. Changes will fully apply after a restart.
timeout /t 3 >nul
