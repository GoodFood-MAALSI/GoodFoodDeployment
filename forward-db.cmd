@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: %~nx0 [restaurateur] [client] [order] [administrateur] [delivery] [...]
    exit /b 1
)

REM Définir les ports spécifiques pour chaque application
set port_restaurateur=5434
set port_client=5433
set port_order=5437
set port_administrateur=5436
set port_delivery=5435

REM Boucle sur tous les arguments
for %%A in (%*) do (
    set "APP=%%A"
    set "NAMESPACE=%%A"
    set "POD_NAME="
    set "PORT="

    REM Sélectionner le port approprié
    if /i "!APP!"=="restaurateur" set "PORT=!port_restaurateur!"
    if /i "!APP!"=="client"       set "PORT=!port_client!"
    if /i "!APP!"=="order"        set "PORT=!port_order!"
    if /i "!APP!"=="administrateur"        set "PORT=!port_administrateur!"
    if /i "!APP!"=="delivery"        set "PORT=!port_delivery!"

    if "!PORT!"=="" (
        echo [!] Port non défini pour "!APP!" – ignoré.
    ) else (
        REM Chercher le pod correspondant
        for /f "tokens=1" %%i in ('kubectl get pods -n !NAMESPACE! --no-headers ^| findstr pod-!APP!') do (
            set "POD_NAME=%%i"
        )

        if "!POD_NAME!"=="" (
            echo [!] Aucun pod pour "!APP!" trouvé dans le namespace "!NAMESPACE!"
        ) else (
            echo [✓] Port-forward: !APP! → !POD_NAME! sur le port !PORT!
            start "forward-!APP!" cmd /k kubectl port-forward -n !NAMESPACE! pod/!POD_NAME! !PORT!:!PORT!
        )
    )
)

exit /b 0
