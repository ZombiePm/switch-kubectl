@echo off
setlocal enabledelayedexpansion

REM Switching kubeconfig by context name
REM Usage:
REM   switch.bat          - list available configs
REM   switch.bat <name>   - switch to config (partial match or number)

set "CONFIG_DIR=%USERPROFILE%\.kube"
set "ACTIVE=%CONFIG_DIR%\config"

if not exist "%CONFIG_DIR%" (
    echo Folder %CONFIG_DIR% not found!
    exit /b 1
)

if "%~1"=="" (
    call :list_configs
    exit /b 0
) else (
    call :switch_to "%~1"
    exit /b !errorlevel!
)

:list_configs
echo Available kubeconfig:
echo.
set /a i=0
for %%f in ("%CONFIG_DIR%\config.*") do (
    set /a i+=1
    for /f "delims=" %%c in ('kubectl --kubeconfig="%%f" config current-context 2^>nul') do (
        echo   !i!^) %%c
    )
)
if exist "%ACTIVE%" (
    echo.
    for /f "delims=" %%c in ('kubectl --kubeconfig="%ACTIVE%" config current-context 2^>nul') do (
        echo Active: %%c
    )
)
if !i! equ 0 echo   (no saved configs)
exit /b 0

:switch_to
set "target=%~1"
set "match="
set "match_ctx="
set "match_file="
set /a matches=0

REM Try as number first
set "is_num=1"
for /f "delims=0123456789" %%a in ("%target%") do set "is_num=0"
if "%is_num%"=="1" (
    set /a idx=0
    for %%f in ("%CONFIG_DIR%\config.*") do (
        set /a idx+=1
        if !idx! equ %target% (
            set "match_file=%%f"
            for /f "delims=" %%c in ('kubectl --kubeconfig="%%f" config current-context 2^>nul') do set "match_ctx=%%c"
            set /a matches=1
        )
    )
)

REM If not found by number, search by name (partial match)
if !matches! equ 0 (
    for %%f in ("%CONFIG_DIR%\config.*") do (
        for /f "delims=" %%c in ('kubectl --kubeconfig="%%f" config current-context 2^>nul') do (
            echo %%c | findstr /i "%target%" >nul 2>&1
            if !errorlevel! equ 0 (
                set "match_file=%%f"
                set "match_ctx=%%c"
                set /a matches+=1
            )
        )
    )
)

if !matches! equ 0 (
    echo Config not found: %target%
    echo.
    call :list_configs
    exit /b 1
)
if !matches! gtr 1 (
    echo Ambiguous, found !matches! matches for '%target%':
    for %%f in ("%CONFIG_DIR%\config.*") do (
        for /f "delims=" %%c in ('kubectl --kubeconfig="%%f" config current-context 2^>nul') do (
            echo %%c | findstr /i "%target%" >nul 2>&1
            if !errorlevel! equ 0 echo   - %%c
        )
    )
    exit /b 1
)

REM Check if already active
if exist "%ACTIVE%" (
    for /f "delims=" %%c in ('kubectl --kubeconfig="%ACTIVE%" config current-context 2^>nul') do set "current_ctx=%%c"
    if "!current_ctx!"=="!match_ctx!" (
        echo Already active: !match_ctx!
        exit /b 0
    )
    ren "%ACTIVE%" "config.!current_ctx!"
)

REM Activate selected
move "!match_file!" "%ACTIVE%" >nul
echo !match_ctx!
exit /b 0
