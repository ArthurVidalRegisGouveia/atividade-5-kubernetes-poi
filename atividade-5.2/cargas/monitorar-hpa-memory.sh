#!/bin/bash

CENARIO="${1:?Informe o nome do cenario}"
DIRETORIO="$HOME/atividade-5.2/resultados/$CENARIO"

mkdir -p "$DIRETORIO"

ARQUIVO="$DIRETORIO/metricas.csv"

echo "data_utc,cpu_millicores,memoria_mib,replicas_prontas,replicas_desejadas,hpa_atual,hpa_meta" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  METRICAS=$(kubectl top pods -n poi-atividade5 --no-headers 2>/dev/null |
    awk '$1 ~ /^poi-memory-/ {print $2 "," $3; exit}')

  CPU=$(echo "$METRICAS" | cut -d, -f1 | tr -d 'm')
  MEMORIA=$(echo "$METRICAS" | cut -d, -f2 | tr -d 'Mi')

  REPLICAS_PRONTAS=$(kubectl get deployment poi-memory \
    -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}')

  REPLICAS_DESEJADAS=$(kubectl get deployment poi-memory \
    -n poi-atividade5 \
    -o jsonpath='{.spec.replicas}')

  HPA=$(kubectl get hpa poi-memory-hpa \
    -n poi-atividade5 \
    -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null)

  META=$(kubectl get hpa poi-memory-hpa \
    -n poi-atividade5 \
    -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)

  echo "$DATA,$CPU,$MEMORIA,$REPLICAS_PRONTAS,$REPLICAS_DESEJADAS,$HPA,$META" >> "$ARQUIVO"

  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
