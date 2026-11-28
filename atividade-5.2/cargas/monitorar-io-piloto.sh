#!/bin/bash

DIRETORIO="$HOME/atividade-5.2/resultados/io-piloto"
ARQUIVO="$DIRETORIO/metricas.csv"

mkdir -p "$DIRETORIO"
echo "data_utc,cpu_millicores,memoria_mib,replicas_prontas" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  METRICAS=$(kubectl top pods -n poi-atividade5 --no-headers 2>/dev/null |
    awk '$1 ~ /^poi-io-/ {print $2 "," $3; exit}')

  CPU=$(echo "$METRICAS" | cut -d, -f1 | tr -d 'm')
  MEMORIA=$(echo "$METRICAS" | cut -d, -f2 | tr -d 'Mi')

  REPLICAS=$(kubectl get deployment poi-io \
    -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}')

  echo "$DATA,$CPU,$MEMORIA,$REPLICAS" >> "$ARQUIVO"
  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
