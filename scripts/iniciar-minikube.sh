#!/usr/bin/env bash
set -euo pipefail

# Executar como usuario comum, na VM Ubuntu do OpenStack.
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Nao execute o Minikube como root." >&2
  exit 1
fi
for cmd in docker minikube kubectl; do
  command -v "$cmd" >/dev/null || { echo "Comando ausente: $cmd" >&2; exit 1; }
done
if ! docker info >/dev/null 2>&1; then
  echo "Sem acesso ao daemon Docker. Verifique o servico e reconecte-se ao SSH apos entrar no grupo docker." >&2
  exit 1
fi

echo "Iniciando Minikube de um no com driver Docker..."
minikube start --driver=docker --cpus=3 --memory=6144 --disk-size=12g --container-runtime=containerd

echo "Conferindo estado do cluster..."
minikube status
kubectl get nodes -o wide
echo
echo "O cluster foi iniciado somente nesta VM. Nenhum listener Octavia foi alterado."
echo "NodePorts do driver Docker nao sao automaticamente expostos na interface externa da VM."
