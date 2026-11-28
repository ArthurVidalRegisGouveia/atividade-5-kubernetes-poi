#!/bin/bash

CENARIO="${1:?Informe o cenario}"
DIRETORIO="$HOME/atividade-5.2/resultados/$CENARIO"
ARQUIVO="$DIRETORIO/metricas.csv"

mkdir -p "$DIRETORIO"

echo "data_utc,cpu_millicores,memoria_mib,replicas_prontas,vpa_cpu_recomendada,vpa_memoria_recomendada" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  METRICAS=$(kubectl top pods -n poi-atividade5 --no-headers 2>/dev/null |
    awk '$1 ~ /^poi-cpu-/ {print $2 "," $3; exit}')

  CPU=$(echo "$METRICAS" | cut -d, -f1 | tr -d 'm')
  MEMORIA=$(echo "$METRICAS" | cut -d, -f2 | tr -d 'Mi')

  REPLICAS=$(kubectl get deployment poi-cpu -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

  RECOMENDACAO_CPU=$(kubectl get vpa poi-cpu-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.cpu}' 2>/dev/null)

  RECOMENDACAO_MEMORIA=$(kubectl get vpa poi-cpu-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.memory}' 2>/dev/null)

  echo "$DATA,$CPU,$MEMORIA,$REPLICAS,$RECOMENDACAO_CPU,$RECOMENDACAO_MEMORIA" >> "$ARQUIVO"

  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
