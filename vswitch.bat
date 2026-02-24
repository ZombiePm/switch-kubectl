@echo off
setlocal enabledelayedexpansion

REM Switching kubeconfig via Vault (secret/kube/<name>)
REM Usage:
REM   vswitch.bat              - list configs from Vault
REM   vswitch.bat <number>     - switch by number
REM   vswitch.bat <name>       - switch by partial name
REM   vswitch.bat init         - upload local configs to Vault

set "ACTIVE=%USERPROFILE%\.kube\config"

REM Check vault CLI
where vault >nul 2>&1
if errorlevel 1 (
    echo vault CLI not found
    exit /b 1
)
if "%VAULT_ADDR%"=="" (
    echo VAULT_ADDR not set
    exit /b 1
)

if "%~1"=="" (
    call :list_configs
    exit /b 0
)
if "%~1"=="init" (
    call :init_configs
    exit /b 0
)
call :switch_to "%~1"
exit /b !errorlevel!

:list_configs
set "current_ctx="
if exist "%ACTIVE%" (
    for /f "delims=" %%c in ('kubectl config current-context 2^>nul') do set "current_ctx=%%c"
)

set /a i=0
set "has_names=0"
for /f "delims=" %%n in ('vault kv list -format=json secret/kube 2^>nul ^| python -c "import sys,json;[print(x) for x in json.load(sys.stdin)]" 2^>nul') do (
    if !i! equ 0 (
        echo Configs in Vault:
        echo.
    )
    set /a i+=1
    set "has_names=1"
    if "%%n"=="!current_ctx!" (
        echo   !i!^) %%n  *
    ) else (
        echo   !i!^) %%n
    )
)
if !has_names! equ 0 (
    echo No configs in Vault ^(secret/kube/^)
    exit /b 0
)
if defined current_ctx (
    echo.
    echo Active: !current_ctx!
)
exit /b 0

:switch_to
set "target=%~1"
set "match="
set /a matches=0

REM Collect names into temp file
set "tmpnames=%TEMP%\vswitch_names.tmp"
vault kv list -format=json secret/kube 2>nul | python -c "import sys,json;[print(x) for x in json.load(sys.stdin)]" 2>nul > "%tmpnames%"

REM Check if empty
for %%A in ("%tmpnames%") do (
    if %%~zA equ 0 (
        echo No configs in Vault ^(secret/kube/^)
        del "%tmpnames%" 2>nul
        exit /b 1
    )
)

REM Try as number first
set "is_num=1"
for /f "delims=0123456789" %%a in ("%target%") do set "is_num=0"
if "%is_num%"=="1" (
    set /a idx=0
    for /f "delims=" %%n in (%tmpnames%) do (
        set /a idx+=1
        if !idx! equ %target% (
            set "match=%%n"
            set /a matches=1
        )
    )
)

REM If not found by number, search by partial name
if !matches! equ 0 (
    for /f "delims=" %%n in (%tmpnames%) do (
        echo %%n | findstr /i "%target%" >nul 2>&1
        if !errorlevel! equ 0 (
            set "match=%%n"
            set /a matches+=1
        )
    )
)

del "%tmpnames%" 2>nul

if !matches! equ 0 (
    echo Config not found: %target%
    echo.
    call :list_configs
    exit /b 1
)
if !matches! gtr 1 (
    echo Ambiguous, found !matches! matches for '%target%'
    exit /b 1
)

REM Check if already active
if exist "%ACTIVE%" (
    for /f "delims=" %%c in ('kubectl config current-context 2^>nul') do set "current_ctx=%%c"
    if "!current_ctx!"=="!match!" (
        echo Already active: !match!
        exit /b 0
    )
)

REM Download from Vault
if not exist "%USERPROFILE%\.kube" mkdir "%USERPROFILE%\.kube"
vault kv get -field=kubeconfig "secret/kube/!match!" > "%ACTIVE%" 2>nul
if errorlevel 1 (
    echo Error reading secret/kube/!match!
    exit /b 1
)

echo !match!
exit /b 0

:init_configs
set /a uploaded=0
set /a skipped=0

REM Get existing names
set "tmpexist=%TEMP%\vswitch_exist.tmp"
vault kv list -format=json secret/kube 2>nul | python -c "import sys,json;[print(x) for x in json.load(sys.stdin)]" 2>nul > "%tmpexist%"

REM Upload config.* files
for %%f in ("%USERPROFILE%\.kube\config.*") do (
    for /f "delims=" %%c in ('kubectl --kubeconfig="%%f" config current-context 2^>nul') do (
        set "ctx=%%c"
        set "found=0"
        for /f "delims=" %%e in (%tmpexist%) do (
            if "%%e"=="!ctx!" set "found=1"
        )
        if !found! equ 0 (
            vault kv put "secret/kube/!ctx!" kubeconfig=@"%%f" >nul 2>&1
            if !errorlevel! equ 0 (
                echo   + !ctx!
                set /a uploaded+=1
            ) else (
                echo   ! error: !ctx!
            )
        ) else (
            set /a skipped+=1
        )
    )
)

REM Upload active config
if exist "%ACTIVE%" (
    for /f "delims=" %%c in ('kubectl --kubeconfig="%ACTIVE%" config current-context 2^>nul') do (
        set "ctx=%%c"
        set "found=0"
        for /f "delims=" %%e in (%tmpexist%) do (
            if "%%e"=="!ctx!" set "found=1"
        )
        if !found! equ 0 (
            vault kv put "secret/kube/!ctx!" kubeconfig=@"%ACTIVE%" >nul 2>&1
            if !errorlevel! equ 0 (
                echo   + !ctx! ^(active^)
                set /a uploaded+=1
            ) else (
                echo   ! error: !ctx!
            )
        ) else (
            set /a skipped+=1
        )
    )
)

del "%tmpexist%" 2>nul

echo.
echo Uploaded: !uploaded!, skipped: !skipped!
exit /b 0
