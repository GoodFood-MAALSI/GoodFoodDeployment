#!/bin/bash

set -e
set -o pipefail

# Vérifie si Minikube est en cours d'exécution
echo "Checking if Minikube is running..."
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start --driver=docker --cpus=4 --memory=4096
else
    echo "Minikube is already running."
fi

# Crée les namespaces avec Skaffold
echo "Creating namespaces with Skaffold..."
if ! skaffold run -p namespace; then
    echo "Failed to create namespaces. Please check the errors above and fix them before continuing."
    exit 1
fi

# Déploie les CRDs avec Skaffold
echo "Deploying CRDs with Skaffold..."
if ! skaffold run -p crds; then
    echo "Failed to deploy CRDs. Please check the errors above and fix them before continuing."
    exit 1
fi

# Vérifie que les CRDs sont installés
echo "Verifying CRDs are installed..."
if ! kubectl get crd kafkas.kafka.strimzi.io > /dev/null 2>&1; then
    echo "CRD for Kafka not found. Ensure CRDs are correctly installed in Kafka/crds."
    exit 1
fi

if ! kubectl get crd kafkatopics.kafka.strimzi.io > /dev/null 2>&1; then
    echo "CRD for KafkaTopic not found. Ensure CRDs are correctly installed in Kafka/crds."
    exit 1
fi

# Déploie Kafka avec Skaffold
echo "Deploying Kafka with Skaffold..."
if ! skaffold run -p kafka; then
    echo "Failed to deploy Kafka. Please check the errors above and fix them before continuing."
    exit 1
fi

# Attendre que Kafka soit prêt
echo "Waiting for Kafka to be ready..."
COUNTER=0
while ! kubectl get pod -n kafka -l app.kubernetes.io/name=kafka -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; do
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -ge 60 ]; then
        echo "Timeout: Kafka pod did not start after 5 minutes. Check the status of the Kafka cluster and Strimzi operator logs."
        kubectl get pods -n kafka
        echo "Run 'kubectl logs -n kafka -l app=strimzi-cluster-operator' for more details."
        exit 1
    fi
    echo "Kafka pod is not yet running. Waiting..."
    sleep 5
done
echo "Kafka pod is running."

# Attendre que le topic Kafka soit prêt
echo "Waiting for Kafka topic to be ready..."
if ! kubectl wait --for=condition=Ready kafkatopic/client-orders -n kafka --timeout=300s; then
    echo "Kafka topic client-orders is not ready. Check the Kafka cluster status."
    exit 1
fi

# Construire la liste des profils à partir des arguments
PROFILES=()
if [ "$#" -eq 0 ]; then
    echo "No profiles specified. Defaulting to deploying all pods..."
    PROFILES+=("-p" "all")
else
    echo "Deploying specified profiles: $@"
    for arg in "$@"; do
        PROFILES+=("-p" "$arg")
    done
fi

# Lancer Skaffold avec les profils
echo "Starting Skaffold for profiles: ${PROFILES[*]}..."
skaffold dev "${PROFILES[@]}"