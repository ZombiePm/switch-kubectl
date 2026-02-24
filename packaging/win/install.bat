@echo off
setlocal

echo === switch-kubectl installer ===
echo.

set "DEST=%USERPROFILE%\bin"

if not exist "%DEST%" (
    echo Creating %DEST% ...
    mkdir "%DEST%"
)

echo Copying switch.bat ...
copy /y "%~dp0switch.bat" "%DEST%\switch.bat" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy switch.bat
    exit /b 1
)

echo Copying vswitch.bat ...
copy /y "%~dp0vswitch.bat" "%DEST%\vswitch.bat" >nul
if errorlevel 1 (
    echo ERROR: Failed to copy vswitch.bat
    exit /b 1
)

REM Check if %DEST% is in PATH
echo %PATH% | findstr /i /c:"%DEST%" >nul 2>&1
if errorlevel 1 (
    echo.
    echo NOTE: %DEST% is not in your PATH.
    echo Run this command to add it permanently:
    echo.
    echo   setx PATH "%%PATH%%;%DEST%"
    echo.
)

echo.
echo Done! Commands available: switch, vswitch
echo.
pause
