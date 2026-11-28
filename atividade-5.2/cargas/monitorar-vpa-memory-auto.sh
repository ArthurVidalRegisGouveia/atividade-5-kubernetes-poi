#!/bin/bash

DIRETORIO="$HOME/atividade-5.2/resultados/vpa-memory-auto"
ARQUIVO="$DIRETORIO/metricas.csv"

mkdir -p "$DIRETORIO"

echo "data_utc,pod,cpu_millicores,memoria_mib,replicas_prontas,cpu_request,memoria_request,cpu_limit,memoria_limit,vpa_cpu_recomendada,vpa_memoria_recomendada" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  REPLICAS=$(kubectl get deployment poi-memory -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

  VPA_CPU=$(kubectl get vpa poi-memory-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.cpu}' 2>/dev/null)

  VPA_MEMORIA=$(kubectl get vpa poi-memory-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.memory}' 2>/dev/null)

  PODS=$(kubectl get pods -n poi-atividade5 -l app=poi-memory \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}')

  METRICAS=$(kubectl top pods -n poi-atividade5 --no-headers 2>/dev/null)

  for POD in $PODS; do
    USO=$(echo "$METRICAS" | awk -v p="$POD" '$1 == p {print $2 "," $3}')

    CPU=$(echo "$USO" | cut -d, -f1 | sed 's/m$//')
    MEMORIA=$(echo "$USO" | cut -d, -f2 | sed 's/Mi$//')

    RECURSOS=$(kubectl get pod "$POD" -n poi-atividade5 \
      -o jsonpath='{.spec.containers[0].resources.requests.cpu},{.spec.containers[0].resources.requests.memory},{.spec.containers[0].resources.limits.cpu},{.spec.containers[0].resources.limits.memory}' 2>/dev/null)

    echo "$DATA,$POD,$CPU,$MEMORIA,$REPLICAS,$RECURSOS,$VPA_CPU,$VPA_MEMORIA" >> "$ARQUIVO"
  done

  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
