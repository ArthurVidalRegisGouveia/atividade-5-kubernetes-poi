#!/bin/bash

ARQUIVO="$HOME/atividade-5.2/resultados/memory-piloto/metricas.csv"

echo "data_utc,cpu_millicores,memoria_mib,replicas_prontas" > "$ARQUIVO"

for i in $(seq 1 18); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  METRICAS=$(kubectl top pods -n poi-atividade5 --no-headers 2>/dev/null |
    awk '$1 ~ /^poi-memory-/ {print $2 "," $3; exit}')

  REPLICAS=$(kubectl get deployment poi-memory \
    -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}')

  CPU=$(echo "$METRICAS" | cut -d, -f1 | tr -d 'm')
  MEMORIA=$(echo "$METRICAS" | cut -d, -f2 | tr -d 'Mi')

  echo "$DATA,$CPU,$MEMORIA,$REPLICAS" >> "$ARQUIVO"
  sleep 10
done

echo "Monitoramento concluído: $ARQUIVO"
