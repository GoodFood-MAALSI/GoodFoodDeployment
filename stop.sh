#!/bin/bash

# Arrêter Skaffold et nettoyer
echo "Stopping Skaffold and cleaning up..."
skaffold delete

# Supprimer les CRDs Traefik
echo "Cleaning up Traefik CRDs..."
kubectl delete -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml

# Arrêter Minikube
echo "Stopping Minikube..."
minikube stop

echo "Done! You can now close Docker Desktop if needed."