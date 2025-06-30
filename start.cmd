@echo off
setlocal EnableDelayedExpansion

REM Check Minikube status
echo Checking if Minikube is running...
minikube status | findstr "Running" >nul
if errorlevel 1 (
    echo Starting Minikube...
    minikube start --driver=docker --cpus=3 --memory=5120
) else (
    echo Minikube is already running.
)

REM Check if namespaces already exist
echo Checking if namespaces exist...
kubectl get namespace traefik >nul 2>&1
if errorlevel 1 (
    echo Creating namespaces with Skaffold...
    skaffold run -p namespace
    if errorlevel 1 (
        echo Failed to create namespaces. Please check the errors above and fix them before continuing.
        exit /b 1
    )
) else (
    echo Namespaces already exist, skipping namespace creation.
)

REM Check if CRDs are already installed
echo Checking if CRDs are installed...
kubectl get crd ingressroutes.traefik.io >nul 2>&1
if errorlevel 1 (
    echo Deploying CRDs with Skaffold...
    skaffold run -p crds
    if errorlevel 1 (
        echo Failed to deploy CRDs. Please check the errors above and fix them before continuing.
        exit /b 1
    )
) else (
    echo CRDs already installed, skipping CRD deployment.
)

REM Check if Traefik is already running
echo Checking if Traefik is running...
kubectl get pod -n traefik -l app.kubernetes.io/name=traefik -o jsonpath="{.items[0].status.phase}" 2>nul | findstr "Running" >nul
if errorlevel 1 (
    echo Deploying Traefik with Skaffold...
    skaffold run -p traefik
    if errorlevel 1 (
        echo Failed to deploy Traefik. Please check the errors above and fix them before continuing.
        exit /b 1
    )
) else (
    echo Traefik is already running, skipping Traefik deployment.
)

@REM REM Check if Kafka is already running
@REM echo Checking if Kafka is running...
@REM kubectl get pod -n kafka -l app=kafka -o jsonpath="{.items[0].status.phase}" 2>nul | findstr "Running" >nul
@REM if errorlevel 1 (
@REM     echo Deploying Kafka with Skaffold...
@REM     skaffold run -p kafka
@REM     if errorlevel 1 (
@REM         echo Failed to deploy Kafka. Please check the errors above and fix them before continuing.
@REM         exit /b 1
@REM     )

@REM     REM Wait for Kafka to be ready
@REM     echo Waiting for Kafka to be ready...
@REM     set /a COUNTER=0
@REM     :wait_for_kafka
@REM     kubectl get pod -n kafka -l app=kafka -o jsonpath="{.items[0].status.phase}" 2>nul | findstr "Running" >nul
@REM     if errorlevel 1 (
@REM         set /a COUNTER+=1
@REM         if !COUNTER! GEQ 60 (
@REM             echo Timeout: Kafka pod did not start after 5 minutes. Check the status of the Kafka pods.
@REM             kubectl get pods -n kafka
@REM             echo Run 'kubectl logs -n kafka -l app=kafka' for more details.
@REM             exit /b 1
@REM         )
@REM         echo Kafka pod is not yet running. Waiting...
@REM         timeout /t 5 /nobreak >nul
@REM         goto wait_for_kafka
@REM     )
@REM     echo Kafka pod is running.
@REM ) else (
@REM     echo Kafka is already running, skipping Kafka deployment.
@REM )

REM Check if Access Service is already deployed
echo Checking if Access Service is running...
kubectl get pod -l app=access-service -o jsonpath="{.items[0].status.phase}" 2>nul | findstr "Running" >nul
if errorlevel 1 (
    echo Deploying Access Service with Skaffold...
    skaffold run -p access-service
    if errorlevel 1 (
        echo Failed to deploy Access Service. Please check the errors above and fix them before continuing.
        exit /b 1
    )
) else (
    echo Access Service is already running, skipping deployment.
)


REM Build list of profiles from arguments
set "PROFILES="
:loop_args
if "%1"=="" goto end_loop_args
if not "!PROFILES!"=="" set "PROFILES=!PROFILES! "
set "PROFILES=!PROFILES!-p %1"
shift
goto loop_args
:end_loop_args

if "!PROFILES!"=="" (
    echo No profiles specified. Defaulting to deploying all application pods...
    set "PROFILES=-p all"
) else (
    echo Deploying specified profiles: !PROFILES!
)

echo Starting Skaffold for profiles: !PROFILES!...
skaffold dev !PROFILES!