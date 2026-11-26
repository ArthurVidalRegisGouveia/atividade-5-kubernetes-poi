# Atividade 5.1 — Infraestrutura Kubernetes (POI)

Grupo: Arthur e Pedro. **Preencher matrículas e identificação oficial do grupo.**

## Objetivo

Implantar as três aplicações FastAPI das atividades anteriores em um cluster Kubernetes de nó único usando Minikube na nuvem OpenStack do LSD.

## Requisitos de infraestrutura

- VM Ubuntu Server 22.04/24.04 LTS, flavor `general.large` (4 vCPUs, 8 GiB RAM).
- Cluster criado com Minikube; `kubectl` instalado na VM.
- Exposição externa pelo balanceador Octavia existente, com configuração dos encaminhamentos **a validar após o provisionamento**.

## Manifestos

- `kubernetes/namespace.yaml`: namespace `poi-atividade5`.
- `kubernetes/*-deployment.yaml`: Deployment com uma réplica, probes HTTP e limites de recursos por API.
- `kubernetes/*-service.yaml`: Service do tipo NodePort para cada API.

| Aplicação | Imagem | Porta do container | NodePort planejado |
| --- | --- | ---: | ---: |
| CPU | `arthuurvidaal/poi-cpu:atividade4` | 8001 | 30081 |
| Memory | `arthuurvidaal/poi-memory:atividade4` | 8002 | 30082 |
| I/O | `arthuurvidaal/poi-io:atividade4` | 8003 | 30083 |

**Atenção:** as portas NodePort só ficam disponíveis na rede do nó Minikube. Com o driver Docker, isso **não garante** acesso pela interface da VM no OpenStack; será necessário testar e configurar uma ponte/encaminhamento adequado antes de alterar os pools do Octavia. Os endereços públicos definitivos ainda não foram validados na Atividade 5.

## Escolhas de workloads

Foram definidos três `Deployment`, pois as APIs FastAPI não exigem identidade persistente de Pod e se beneficiam da reconciliação por ReplicaSet e da atualização declarativa. A configuração inicial usa uma réplica por aplicação para caber em um cluster Minikube de um nó. `readinessProbe` e `livenessProbe` consultam `/health`.

O armazenamento de trabalho da API I/O usa `emptyDir`: adequado para arquivos temporários descartáveis, **sem persistência** após a exclusão do Pod. Caso seja exigida persistência, será necessário configurar PV/PVC após validar o ambiente de armazenamento.

## Aplicação dos manifestos — executar apenas após instalar e iniciar Minikube

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/
kubectl -n poi-atividade5 get deployments,pods,services -o wide
bash scripts/validar-cluster.sh
```

## Situação atual

- [x] Imagens Docker Hub existentes da Atividade 4.
- [x] Manifestos iniciais preparados para versionamento.
- [ ] VM `general.large` provisionada (quota do projeto estava esgotada na última consulta).
- [ ] Minikube instalado e inicializado.
- [ ] Deployments implantados e testados no Kubernetes.
- [ ] Exposição pela VM e pelo Octavia validada externamente.

Não publicar arquivos OpenStack RC, senhas, tokens, chaves privadas SSH nem `.kube/config` neste repositório.
