@echo off
setlocal EnableDelayedExpansion

REM Check Minikube status
echo Checking if Minikube is running...
minikube status | findstr "Running" >nul
if errorlevel 1 (
    echo Starting Minikube...
    minikube start --driver=docker --cpus=4 --memory=4096
) else (
    echo Minikube is already running.
)

REM Create namespaces with Skaffold
echo Creating namespaces with Skaffold...
skaffold run -p namespace
if errorlevel 1 (
    echo Failed to create namespaces. Please check the errors above and fix them before continuing.
    exit /b 1
)

REM Deploy CRDs with Skaffold
echo Deploying CRDs with Skaffold...
skaffold run -p crds
if errorlevel 1 (
    echo Failed to deploy CRDs. Please check the errors above and fix them before continuing.
    exit /b 1
)

REM Verify CRDs are installed
echo Verifying CRDs are installed...
kubectl get crd kafkas.kafka.strimzi.io >nul 2>&1
if errorlevel 1 (
    echo CRD for Kafka not found. Ensure CRDs are correctly installed in Kafka/crds.
    exit /b 1
)
kubectl get crd kafkatopics.kafka.strimzi.io >nul 2>&1
if errorlevel 1 (
    echo CRD for KafkaTopic not found. Ensure CRDs are correctly installed in Kafka/crds.
    exit /b 1
)

REM Deploy Kafka with Skaffold
echo Deploying Kafka with Skaffold...
skaffold run -p kafka
if errorlevel 1 (
    echo Failed to deploy Kafka. Please check the errors above and fix them before continuing.
    exit /b 1
)

REM Wait for Kafka to be ready
echo Waiting for Kafka to be ready...
set /a COUNTER=0
:wait_for_kafka
kubectl get pod -n kafka -l app.kubernetes.io/name=kafka -o jsonpath="{.items[0].status.phase}" 2>nul | findstr "Running" >nul
if errorlevel 1 (
    set /a COUNTER+=1
    if !COUNTER! GEQ 60 (
        echo Timeout: Kafka pod did not start after 5 minutes. Check the status of the Kafka cluster and Strimzi operator logs.
        kubectl get pods -n kafka
        echo Run 'kubectl logs -n kafka -l app=strimzi-cluster-operator' for more details.
        exit /b 1
    )
    echo Kafka pod is not yet running. Waiting...
    timeout /t 5 /nobreak >nul
    goto wait_for_kafka
)
echo Kafka pod is running.

REM Wait for Kafka topic readiness
echo Waiting for Kafka topic to be ready...
kubectl wait --for=condition=Ready kafkatopic/client-orders -n kafka --timeout=300s
if errorlevel 1 (
    echo Kafka topic client-orders is not ready. Check the Kafka cluster status.
    exit /b 1
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
    echo No profiles specified. Defaulting to deploying all pods...
    set "PROFILES=-p all"
) else (
    echo Deploying specified profiles: !PROFILES!
)

echo Starting Skaffold for profiles: !PROFILES!...
skaffold dev !PROFILES!