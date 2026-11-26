# Atividade 5.1 — Infraestrutura Kubernetes (POI)

**Grupo 23:** Arthur Vidal Regis Gouveia (123110755) e Pedro Henriques Barros Pereira (123110565).

## Objetivo

Implantar as tres APIs FastAPI (CPU-bound, Memory-bound e I/O-bound) num cluster Kubernetes Minikube de um no, em VM Ubuntu no OpenStack LSD, disponibilizadas via balanceador Octavia.

> **Status:** scripts, imagens e manifestos preparados; **VM/cluster ainda nao criados devido a quota de 96/96 vCPUs e 196608/196608 MiB de RAM** na ultima verificacao. Nao confunda testes offline com deploy realizado.

## Infraestrutura prevista

- VM `vm-arthur-pedro-k8s`: Ubuntu Server 24.04, flavor `general.large` (4 vCPU/8 GiB RAM/20 GB disco).
- Rede OpenStack `provider`; chave publica `arthur-pedro-k8s` cadastrada.
- Minikube no driver Docker. Acesso por Octavia **sera configurado somente apos testes do backend**.

## Manifestos

| App | Imagem | Porta HTTP do container | NodePort planejado |
| --- | --- | ---: | ---: |
| CPU | `arthuurvidaal/poi-cpu:atividade4` | 8001 | 30081 |
| Memory | `arthuurvidaal/poi-memory:atividade4` | 8002 | 30082 |
| I/O | `arthuurvidaal/poi-io:atividade4` | 8003 | 30083 |

`kubernetes/namespace.yaml` define `poi-atividade5`; cada app usa Deployment de uma replica e Service NodePort. Deployment foi escolhido por reconciliacao de replicas e atualizacao declarativa. As verificacoes `/health` sao feitas por liveness/readiness probes. A API I/O usa volume `emptyDir`, sem persistencia apos exclusao do Pod.

## Organizacao

- `kubernetes/`: 7 manifestos YAML.
- `scripts/verificar-openstack.sh`: diagnostico OpenStack somente leitura, para rodar **na VDI**.
- `scripts/validar-manifestos-offline.py`: analise offline de YAML com PyYAML, para rodar **na VDI** ou outro ambiente Python.
- `scripts/instalar-dependencias.sh`, `scripts/iniciar-minikube.sh`: somente **na nova VM Ubuntu OpenStack**, apos provisionamento.
- `scripts/validar-cluster.sh`, `scripts/testar-aplicacoes.sh`: somente **com Minikube funcional**.
- `documentacao/Atividade-5.1-Infraestrutura-Kubernetes.md`: relatorio com resultados observados e pendencias.
- `documentacao/ROTEIRO-PENDENTE-QUOTA.md`: roteiro passo a passo da criacao da VM ate os testes externos.

## Verificacoes offline (na VDI)

```bash
cd ~/atividade-5-kubernetes-poi
git pull origin main
python3 scripts/validar-manifestos-offline.py
# Com OpenStack RC carregado:
bash scripts/verificar-openstack.sh
```

As tres imagens ja foram consultadas com `docker manifest inspect` e retornaram OK. Os sete YAMLs passaram numa verificacao previa com PyYAML 5.4.1. A validacao de schema Kubernetes e o deploy permanecem pendentes.

## Execucao futura, APENAS na nova VM

```bash
git clone https://github.com/ArthurVidalRegisGouveia/atividade-5-kubernetes-poi.git
cd atividade-5-kubernetes-poi
bash scripts/instalar-dependencias.sh
# Reconectar via SSH para ativar grupo docker
bash scripts/iniciar-minikube.sh
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/
bash scripts/validar-cluster.sh
bash scripts/testar-aplicacoes.sh
```

**Importante:** os NodePorts do Minikube com driver Docker nao sao expostos automaticamente na interface da VM OpenStack; validar o caminho real antes de ajustar pools Octavia. O balanceador e compartilhado com outras equipes e possui estado operacional ERROR na consulta anterior; modificar apenas membros dos nossos pools apos inspecao.

Nunca versionar chaves privadas SSH, arquivos OpenStack RC, tokens ou senhas.
