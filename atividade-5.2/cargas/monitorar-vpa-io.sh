#!/bin/bash

DIRETORIO="$HOME/atividade-5.2/resultados/vpa-io-off"
ARQUIVO="$DIRETORIO/metricas.csv"

mkdir -p "$DIRETORIO"

echo "data_utc,cpu_millicores,memoria_mib,replicas_prontas,cpu_request,memoria_request,vpa_cpu_recomendada,vpa_memoria_recomendada" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  POD=$(kubectl get pods -n poi-atividade5 -l app=poi-io \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

  METRICAS=$(kubectl top pod "$POD" -n poi-atividade5 --no-headers 2>/dev/null)

  CPU=$(echo "$METRICAS" | awk '{gsub(/m$/, "", $2); print $2}')
  MEMORIA=$(echo "$METRICAS" | awk '{gsub(/Mi$/, "", $3); print $3}')

  REPLICAS=$(kubectl get deployment poi-io -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

  RECURSOS=$(kubectl get pod "$POD" -n poi-atividade5 \
    -o jsonpath='{.spec.containers[0].resources.requests.cpu},{.spec.containers[0].resources.requests.memory}' 2>/dev/null)

  VPA_CPU=$(kubectl get vpa poi-io-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.cpu}' 2>/dev/null)

  VPA_MEMORIA=$(kubectl get vpa poi-io-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.memory}' 2>/dev/null)

  echo "$DATA,$CPU,$MEMORIA,$REPLICAS,$RECURSOS,$VPA_CPU,$VPA_MEMORIA" >> "$ARQUIVO"

  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
