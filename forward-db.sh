#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Usage: $0 [restaurateur] [client] [order] [administrateur] [delivery] [...]"
    exit 1
fi

# Définir les ports spécifiques pour chaque application
declare -A ports
ports[restaurateur]=5434
ports[client]=5433
ports[order]=5437
ports[administrateur]=5436
ports[delivery]=5435

# Parcourir chaque argument
for APP in "$@"; do
    NAMESPACE="$APP"
    PORT="${ports[$APP]}"

    if [ -z "$PORT" ]; then
        echo "[!] Port non défini pour \"$APP\" – ignoré."
        continue
    fi

    # Trouver le nom du pod
    POD_NAME=$(kubectl get pods -n "$NAMESPACE" --no-headers | grep "pod-$APP" | awk '{print $1}')

    if [ -z "$POD_NAME" ]; then
        echo "[!] Aucun pod pour \"$APP\" trouvé dans le namespace \"$NAMESPACE\""
        continue
    fi

    echo "[✓] Port-forward: $APP → $POD_NAME sur le port $PORT"
    # Lancer le port-forward en arrière-plan avec un tag visible
    nohup kubectl port-forward -n "$NAMESPACE" pod/"$POD_NAME" "$PORT:$PORT" > "pf-$APP.log" 2>&1 &
done
