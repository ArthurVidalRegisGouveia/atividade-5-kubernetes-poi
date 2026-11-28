#!/bin/bash
set -u

CENARIO="${1:?Informe o nome do cenario}"
DIRETORIO="$HOME/atividade-5.2/resultados/$CENARIO"
ARQUIVO="$DIRETORIO/metricas.csv"

mkdir -p "$DIRETORIO"

echo "data_utc,cpu_total_millicores,memoria_total_mib,pods_com_metricas,replicas_prontas,replicas_desejadas,hpa_atual,hpa_meta" > "$ARQUIVO"

for i in $(seq 1 24); do
  DATA=$(date -u +%Y-%m-%dT%H:%M:%SZ)

  METRICAS=$(kubectl top pods -n poi-atividade5 --no-headers 2>/dev/null |
    awk '$1 ~ /^poi-io-/ {
      cpu=$2
      mem=$3
      sub(/m$/, "", cpu)
      sub(/Mi$/, "", mem)
      total_cpu+=cpu
      total_mem+=mem
      n++
    }
    END {
      if (n > 0) print total_cpu "," total_mem "," n
      else print ",,"
    }')

  CPU=$(echo "$METRICAS" | cut -d, -f1)
  MEMORIA=$(echo "$METRICAS" | cut -d, -f2)
  PODS=$(echo "$METRICAS" | cut -d, -f3)

  PRONTAS=$(kubectl get deployment poi-io -n poi-atividade5 \
    -o jsonpath='{.status.readyReplicas}' 2>/dev/null)

  DESEJADAS=$(kubectl get deployment poi-io -n poi-atividade5 \
    -o jsonpath='{.spec.replicas}' 2>/dev/null)

  HPA=$(kubectl get hpa poi-io-hpa -n poi-atividade5 \
    -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}' 2>/dev/null)

  META=$(kubectl get hpa poi-io-hpa -n poi-atividade5 \
    -o jsonpath='{.spec.metrics[0].resource.target.averageUtilization}' 2>/dev/null)

  echo "$DATA,$CPU,$MEMORIA,$PODS,$PRONTAS,$DESEJADAS,$HPA,$META" >> "$ARQUIVO"

  sleep 10
done

echo "Monitoramento concluido: $ARQUIVO"
