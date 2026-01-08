@echo off
setlocal

rem Se place a la racine du projet (la ou est ce script)
pushd "%~dp0"

set VERSION=%~1

:MENU
cls
echo ==========================================
echo    DEPLOIEMENT FIRMWARE - Stratum0
if not "%VERSION%"=="" echo    Version cible : %VERSION%
echo ==========================================
echo 1 : Definir/Incrementer la version (Set-Version)
echo 2 : Compiler le firmware (PlatformIO)
echo 3 : Copier et Renommer le .uf2
echo 4 : Git Commit ^& Tag
echo 5 : Git Push
echo.
echo 9 : DEPLOIEMENT COMPLET (Auto)
echo 0 : Sortir
echo ==========================================
set /p CHOICE="Votre choix : "

if "%CHOICE%"=="1" goto DO_VERSION
if "%CHOICE%"=="2" goto DO_BUILD
if "%CHOICE%"=="3" goto DO_RENAME
if "%CHOICE%"=="4" goto DO_GIT
if "%CHOICE%"=="5" goto DO_PUSH
if "%CHOICE%"=="9" goto DO_FULL
if "%CHOICE%"=="0" goto END
goto MENU

:DO_VERSION
call :CHECK_VERSION
if errorlevel 1 goto MENU
powershell -ExecutionPolicy Bypass -File ".\Set-Version.ps1" -Version %VERSION%
if errorlevel 1 (
    echo [ERREUR] Echec de Set-Version.ps1.
) else (
    echo [SUCCES] version.h mis a jour.
)
pause
goto MENU

:DO_BUILD
echo.
echo Compilation avec PlatformIO...
where pio >nul 2>nul
if %errorlevel% equ 0 goto RUN_PIO

set "PIO_PATH=%USERPROFILE%\.platformio\penv\Scripts"
if exist "%PIO_PATH%\pio.exe" (
    echo [INFO] PlatformIO detecte dans %PIO_PATH%
    set "PATH=%PATH%;%PIO_PATH%"
    goto RUN_PIO
)

echo [ERREUR] Commande 'pio' introuvable. PlatformIO est-il installe ?
echo Verifiez que %USERPROFILE%\.platformio\penv\Scripts est dans le PATH.
pause
goto MENU

:RUN_PIO
pio run
if %errorlevel% neq 0 (
    echo [ERREUR] Compilation echouee.
    pause
    goto MENU
)
echo [SUCCES] Compilation reussie.
pause
goto MENU

:DO_RENAME
call :CHECK_VERSION
if errorlevel 1 goto MENU
set "SRC=%CD%\.pio\build\waveshare_rp2040_zero\firmware.uf2"
set "DST=Stratum0_v%VERSION%.uf2"

if exist "%SRC%" goto RENAME_DO_COPY
echo [ERREUR] Fichier source introuvable:
echo "%SRC%"
echo Veuillez compiler le projet d'abord (Option 2).
pause
goto MENU

:RENAME_DO_COPY
copy /Y "%SRC%" "%DST%" >nul
echo [SUCCES] Firmware copie et renomme : %DST%
pause
goto MENU

:DO_GIT
call :CHECK_VERSION
if errorlevel 1 goto MENU
echo.
echo Preparation du commit et du tag pour le firmware...
git add .
git commit -m "Release firmware Stratum0 v%VERSION%" || echo "Info: Pas de nouveaux changements a commiter."
echo.
echo Nettoyage et (re)creation du tag firmware/v%VERSION%...
git tag -d firmware/v%VERSION% >nul 2>&1
git push origin --delete firmware/v%VERSION% >nul 2>&1
git tag firmware/v%VERSION%
echo [SUCCES] Tag firmware/v%VERSION% cree.
pause
goto MENU

:DO_PUSH
echo.
echo Push du firmware vers GitHub...
git push origin main --tags --force
pause
goto MENU

:DO_FULL
call :CHECK_VERSION
if errorlevel 1 goto MENU

echo. & echo ==========================================
echo DEPLOIEMENT COMPLET FIRMWARE v%VERSION%
echo ==========================================

echo. & echo [1/5] Mise a jour de la version...
powershell -ExecutionPolicy Bypass -File ".\Set-Version.ps1" -Version %VERSION%
if errorlevel 1 goto FULL_FAIL

echo. & echo [2/5] Compilation du firmware...
pio run
if errorlevel 1 goto FULL_FAIL

echo. & echo [3/5] Copie et renommage du binaire...
set "SRC=%CD%\.pio\build\waveshare_rp2040_zero\firmware.uf2"
set "DST=Stratum0_v%VERSION%.uf2"
if not exist "%SRC%" echo [ERREUR] Fichier source introuvable: "%SRC%" & goto FULL_FAIL
copy /Y "%SRC%" "%DST%" >nul

echo. & echo [4/5] Validation Git (Commit ^& Tag)...
git add .
git commit -m "Release firmware Stratum0 v%VERSION%" || echo "Info: Pas de changements a commiter."
git tag -d firmware/v%VERSION% >nul 2>&1 & git push origin --delete firmware/v%VERSION% >nul 2>&1
git tag firmware/v%VERSION%
if errorlevel 1 goto FULL_FAIL

echo. & echo [5/5] Push vers le depot distant...
git push origin main --tags --force
if errorlevel 1 goto FULL_FAIL

echo. & echo [SUCCES] Deploiement firmware v%VERSION% termine.
pause & goto MENU

:FULL_FAIL
echo. & echo [ECHEC] Le deploiement complet du firmware a rencontre une erreur.
pause & goto MENU

:CHECK_VERSION
if "%VERSION%"=="" ( set /p VERSION="Entrez la version du firmware (ex: 1.2.3) : " )
if "%VERSION%"=="" ( echo [ERREUR] Version requise. & exit /b 1 )
exit /b 0

:END
popd
exit /b 0