#!/bin/bash

# Check Minikube status
echo "Checking if Minikube is running..."
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start --driver=docker --cpus=4 --memory=4096
else
    echo "Minikube is already running."
fi

# Check if namespaces already exist
echo "Checking if namespaces exist..."
if ! kubectl get namespace kafka >/dev/null 2>&1; then
    echo "Creating namespaces with Skaffold..."
    skaffold run -p namespace
    if [ $? -ne 0 ]; then
        echo "Failed to create namespaces. Please check the errors above and fix them before continuing."
        exit 1
    fi
else
    echo "Namespaces already exist, skipping namespace creation."
fi

# Check if CRDs are already installed
echo "Checking if CRDs are installed..."
if ! kubectl get crd kafkas.kafka.strimzi.io >/dev/null 2>&1; then
    echo "Deploying CRDs with Skaffold..."
    skaffold run -p crds
    if [ $? -ne 0 ]; then
        echo "Failed to deploy CRDs. Please check the errors above and fix them before continuing."
        exit 1
    fi
else
    echo "CRDs already installed, skipping CRD deployment."
fi

# Check if Traefik is already running
echo "Checking if Traefik is running..."
if ! kubectl get pod -n traefik -l app.kubernetes.io/name=traefik -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; then
    echo "Deploying Traefik with Skaffold..."
    skaffold run -p traefik
    if [ $? -ne 0 ]; then
        echo "Failed to deploy Traefik. Please check the errors above and fix them before continuing."
        exit 1
    fi
else
    echo "Traefik is already running, skipping Traefik deployment."
fi

# Check if Kafka is already running
echo "Checking if Kafka is running..."
if ! kubectl get pod -n kafka -l app.kubernetes.io/name=kafka -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; then
    echo "Deploying Kafka with Skaffold..."
    skaffold run -p kafka
    if [ $? -ne 0 ]; then
        echo "Failed to deploy Kafka. Please check the errors above and fix them before continuing."
        exit 1
    fi

    # Wait for Kafka to be ready
    echo "Waiting for Kafka to be ready..."
    COUNTER=0
    while ! kubectl get pod -n kafka -l app.kubernetes.io/name=kafka -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; do
        ((COUNTER++))
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

    # Wait for Kafka topic readiness
    echo "Waiting for Kafka topic to be ready..."
    if ! kubectl wait --for=condition=Ready kafkatopic/auth-validate-reply -n kafka --timeout=300s; then
        echo "Kafka topic auth-validate-reply is not ready. Check the Kafka cluster status."
        exit 1
    fi
else
    echo "Kafka is already running, skipping Kafka deployment."
fi

# Vérifie si le pod Access Service est déjà en cours d'exécution
echo "Checking if Access Service is running..."
STATUS=$(kubectl get pod -l app=access-service -o jsonpath="{.items[0].status.phase}" 2>/dev/null)

if [ "$STATUS" != "Running" ]; then
  echo "Deploying Access Service with Skaffold..."
  skaffold run -p access-service
  if [ $? -ne 0 ]; then
    echo "Failed to deploy Access Service. Please check the errors above and fix them before continuing."
    exit 1
  fi
else
  echo "Access Service is already running, skipping deployment."
fi

# Build list of profiles from arguments
PROFILES=""
for arg in "$@"; do
    if [ -n "$PROFILES" ]; then
        PROFILES="$PROFILES "
    fi
    PROFILES="${PROFILES}-p $arg"
done

if [ -z "$PROFILES" ]; then
    echo "No profiles specified. Defaulting to deploying all application pods..."
    PROFILES="-p all"
else
    echo "Deploying specified profiles: $PROFILES"
fi

echo "Starting Skaffold for profiles: $PROFILES..."
skaffold dev $PROFILES