#!/bin/bash

# Vérifier si Minikube est lancé
echo "Checking if Minikube is running..."
if ! minikube status | grep -q "Running"; then
  echo "Starting Minikube..."
  minikube start --driver=docker --cpus=4 --memory=4096
else
  echo "Minikube is already running."
fi

# Appliquer les CRDs de Traefik
echo "Applying Traefik CRDs..."
kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# Vérifier si un paramètre est fourni
if [ -z "$1" ]; then
  echo "No pod specified. Defaulting to deploying all pods..."
  PROFILES="all"
else
  PROFILES="$1"
fi

# Lancer Skaffold avec les profils
echo "Starting Skaffold for profiles: $PROFILES..."
skaffold dev -p "$PROFILES"