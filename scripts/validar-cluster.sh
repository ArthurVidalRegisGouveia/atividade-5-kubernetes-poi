#!/usr/bin/env bash
set -euo pipefail
NAMESPACE="poi-atividade5"
minikube status
kubectl get nodes -o wide
kubectl -n "$NAMESPACE" get deployments,pods,services -o wide
for app in cpu memory io; do
  kubectl -n "$NAMESPACE" rollout status "deployment/poi-$app" --timeout=180s
done
printf '\nPara testar o acesso via Services, execute na VM do cluster:\n'
printf 'kubectl -n %s get svc\n' "$NAMESPACE"
printf 'ATENÇÃO: NodePort no Minikube com driver Docker pode não estar acessível pela interface da VM/OpenStack.\n'
