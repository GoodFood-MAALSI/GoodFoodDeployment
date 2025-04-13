@echo off
setlocal EnableDelayedExpansion

echo Checking if Minikube is running...
minikube status | findstr "Running" >nul
if errorlevel 1 (
  echo Starting Minikube...
  minikube start --driver=docker --cpus=4 --memory=4096
) else (
  echo Minikube is already running.
)

echo Applying Traefik CRDs...
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

:: Vérifier si un paramètre est fourni
if "%1"=="" (
  echo No pod specified. Defaulting to deploying all pods...
  set PROFILES=all
) else (
  set PROFILES=%1
)

echo Starting Skaffold for profiles: %PROFILES%...
skaffold dev -p %PROFILES%