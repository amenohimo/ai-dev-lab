@echo off
setlocal
title Enable UAC

:: Self-elevate if needed
fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo.
echo Enabling UAC (EnableLUA=1)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" ^
    /v EnableLUA /t REG_DWORD /d 1 /f

if errorlevel 1 (
    echo.
    echo ERROR: Failed to change UAC setting.
    pause
    exit /b 1
)

echo.
echo UAC has been set to ON.
echo A Windows restart is required for this change to take effect.
echo.
choice /C YN /N /M "Restart now? [Y/N]: "
if errorlevel 2 exit /b 0
shutdown /r /t 0
