#!/usr/bin/env bash
set -euo pipefail

# Executar na VM OpenStack, depois que os Deployments estiverem prontos.
# Usa kubectl port-forward para testar os Services sem depender do Octavia.
NS="poi-atividade5"
command -v kubectl >/dev/null || { echo "kubectl nao encontrado" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl nao encontrado" >&2; exit 1; }

kubectl -n "$NS" rollout status deployment/poi-cpu --timeout=180s
kubectl -n "$NS" rollout status deployment/poi-memory --timeout=180s
kubectl -n "$NS" rollout status deployment/poi-io --timeout=180s

testar() {
  local app="$1" porta_local="$2" porta_servico="$3" endpoint="$4"
  local log
  log="$(mktemp)"
  kubectl -n "$NS" port-forward --address 127.0.0.1 "service/poi-$app" "${porta_local}:${porta_servico}" >"$log" 2>&1 &
  local pid=$!
  # Encerrar o encaminhamento mesmo em caso de falha.
  cleanup() { kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; rm -f "$log"; }
  trap cleanup RETURN
  local pronto=0
  for _ in $(seq 1 30); do
    if curl -fsS --max-time 2 "http://127.0.0.1:${porta_local}/health" >/dev/null 2>&1; then
      pronto=1
      break
    fi
    if ! kill -0 "$pid" 2>/dev/null; then break; fi
    sleep 1
  done
  if [[ "$pronto" -ne 1 ]]; then
    echo "ERRO: nao foi possivel acessar poi-$app via port-forward" >&2
    cat "$log" >&2
    return 1
  fi
  echo
  echo "=== poi-$app: /health ==="
  curl -fsS --max-time 10 "http://127.0.0.1:${porta_local}/health"
  echo
  echo "=== poi-$app: teste funcional ==="
  curl -fsS --max-time 60 "http://127.0.0.1:${porta_local}${endpoint}"
  echo
}

testar cpu 19081 8001 "/primos?limite=10000"
testar memory 19082 8002 "/memoria?tamanho_mb=10"
testar io 19083 8003 "/arquivo?tamanho_mb=1&operacoes=1"

echo
echo "Testes locais via Services concluidos. Isso NAO valida acesso externo pelo Octavia."
