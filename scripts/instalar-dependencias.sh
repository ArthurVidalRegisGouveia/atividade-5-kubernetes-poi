#!/usr/bin/env bash
set -euo pipefail

# Executar apenas na VM Ubuntu 22.04/24.04 x86_64 do OpenStack.
if [[ "$(id -u)" -eq 0 ]]; then
  echo "Execute como usuario normal com permissao de sudo, nao como root." >&2
  exit 1
fi
. /etc/os-release
if [[ "$ID" != "ubuntu" || ( "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ) ]]; then
  echo "Sistema nao suportado por este script: $PRETTY_NAME" >&2
  exit 1
fi
if [[ "$(uname -m)" != "x86_64" ]]; then
  echo "Este script exige a arquitetura x86_64." >&2
  exit 1
fi
echo "[1/4] Dependencias basicas"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

echo "[2/4] Docker Engine: repositorio oficial"
# Nao remove instalacoes existentes automaticamente.
if ! command -v docker >/dev/null 2>&1; then
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

echo "[3/4] kubectl: download oficial com verificacao SHA-256"
KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
curl -fsSL -o "$tmpdir/kubectl" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
curl -fsSL -o "$tmpdir/kubectl.sha256" "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"
echo "$(cat "$tmpdir/kubectl.sha256")  $tmpdir/kubectl" | sha256sum --check --status
sudo install -o root -g root -m 0755 "$tmpdir/kubectl" /usr/local/bin/kubectl

echo "[4/4] Minikube: binario oficial"
curl -fsSL -o "$tmpdir/minikube" https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-amd64
sudo install -o root -g root -m 0755 "$tmpdir/minikube" /usr/local/bin/minikube

echo
docker --version
kubectl version --client
minikube version
echo
echo "Instalacao concluida. SAIA da sessao SSH e entre novamente para aplicar o grupo docker."
echo "O cluster ainda NAO foi iniciado. Depois do novo login: bash scripts/iniciar-minikube.sh"
