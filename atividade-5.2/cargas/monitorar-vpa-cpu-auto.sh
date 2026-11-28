#!/bin/bash

DIRETORIO="$HOME/atividade-5.2/resultados/vpa-cpu-auto"
ARQUIVO="$DIRETORIO/metricas.csv"

mkdir -p "$DIRETORIO"

echo "data_utc,pod,cpu_utilizada_m,memoria_utilizada_mib,cpu_request,memoria_request,cpu_limit,memoria_limit,vpa_cpu,vpa_memoria" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  VPA_CPU=$(kubectl get vpa poi-cpu-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.cpu}' 2>/dev/null)

  VPA_MEMORIA=$(kubectl get vpa poi-cpu-vpa -n poi-atividade5 \
    -o jsonpath='{.status.recommendation.containerRecommendations[0].target.memory}' 2>/dev/null)

  kubectl get pods -n poi-atividade5 -l app=poi-cpu \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.spec.containers[0].resources.requests.cpu}{" "}{.spec.containers[0].resources.requests.memory}{" "}{.spec.containers[0].resources.limits.cpu}{" "}{.spec.containers[0].resources.limits.memory}{"\n"}{end}' |
  while read -r POD CPU_REQ MEM_REQ CPU_LIM MEM_LIM; do

    METRICAS=$(kubectl top pod "$POD" -n poi-atividade5 \
      --no-headers 2>/dev/null | awk '{print $2 "," $3}')

    CPU_USO=$(echo "$METRICAS" | cut -d, -f1 | sed 's/m$//')
    MEM_USO=$(echo "$METRICAS" | cut -d, -f2 | sed 's/Mi$//')

    echo "$DATA,$POD,$CPU_USO,$MEM_USO,$CPU_REQ,$MEM_REQ,$CPU_LIM,$MEM_LIM,$VPA_CPU,$VPA_MEMORIA" \
      >> "$ARQUIVO"
  done

  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
