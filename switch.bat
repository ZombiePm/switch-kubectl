@echo off
setlocal enabledelayedexpansion

REM Config folder
set "CONFIG_DIR=%USERPROFILE%\.kube"

if not exist "%CONFIG_DIR%" (
    echo Folder %CONFIG_DIR% not found!
    exit /b 1
)

cd /d "%CONFIG_DIR%"

REM Current UTC timestamp YYYYMMDDHHMMSS
for /f "tokens=1-7 delims=.: " %%a in ('wmic os get LocalDateTime ^| find "."') do set dt=%%a
set TS=%dt:~0,14%

REM Rename current config if exists
if exist config (
    ren config config.%TS%
    echo Old config renamed to: config.%TS%
)

REM Find the oldest config.* (exclude just renamed file)
set OLDEST=
for /f "delims=" %%f in ('dir /b /a-d config.* 2^>nul ^| sort') do (
    if not "%%f"=="config.%TS%" (
        if not defined OLDEST set OLDEST=%%f
    )
)

REM Activate the oldest config
if defined OLDEST (
    ren "%OLDEST%" config
    echo Switched to: config (from %OLDEST%)
) else (
    echo No older configs to switch!
)

REM Show current kubectl context
call kubectl config current-context
