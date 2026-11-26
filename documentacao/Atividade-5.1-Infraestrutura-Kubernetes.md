# Atividade 5.1 — Infraestrutura Kubernetes

**Grupo:** 23  
**Alunos:** Arthur Vidal Regis Gouveia (123110755) e Pedro Henriques Barros Pereira (123110565)  
**Data da validação:** 26/11/2026

Resumo técnico da implantação. O relatório formal, com capturas de tela, é entregue separadamente em Google Docs.

## Configuração da VM e ambiente da Cloud

Foi criada no OpenStack LSD, projeto `Provisionamento`, a VM `vm-arthur-pedro-k8s` com Ubuntu 24.04, flavor `general.large` (4 vCPUs e 8 GiB RAM), rede `provider` e security group `sg-arthur-pedro-poi`.

| Item | Configuração |
| --- | --- |
| ID da VM | `2efda93b-1f22-4bfa-bd5a-9b750b5b44b5` |
| IP privado | `10.5.10.123` |
| Estado observado | `ACTIVE` |
| IP público do Octavia | `150.165.85.77` |
| Acesso SSH pelo Octavia | Porta `22022` |

O balanceador compartilhado `poi-atividades` encaminha as portas públicas 18001, 18002 e 18003 às portas 8001, 8002 e 8003 da VM. Os membros HTTP antigos foram desabilitados. O estado global `operating_status=ERROR` não teve causa determinada, mas os acessos HTTP deste grupo funcionaram.

## Deploy e configuração do cluster Kubernetes

Na VM foram instalados Docker, `kubectl` e Minikube. O cluster utiliza driver Docker, 3 vCPUs e 6144 MiB de RAM; o nó Kubernetes v1.37.0 ficou `Ready`.

```bash
bash scripts/instalar-dependencias.sh
bash scripts/iniciar-minikube.sh
minikube status
kubectl get nodes -o wide
```

Como os NodePorts do Minikube não ficam diretamente expostos no IP da VM, os três Services são acessados por `kubectl port-forward` supervisionado por unidades `systemd`. A unidade `poi-minikube.service` inicializa o cluster após o Docker. As quatro unidades foram verificadas como `enabled` e `active` após reinicialização controlada.

## Deploy das Aplicações

Foram aplicados sete manifestos: um Namespace `poi-atividade5`, três Deployments (uma réplica cada) e três Services `NodePort`.

| Aplicação | Imagem | Deployment | Service | NodePort | URL pública |
| --- | --- | --- | --- | --- | --- |
| CPU | `arthuurvidaal/poi-cpu:atividade4` | [YAML](../kubernetes/cpu-deployment.yaml) | [YAML](../kubernetes/cpu-service.yaml) | 30081 | http://150.165.85.77:18001/health |
| Memória | `arthuurvidaal/poi-memory:atividade4` | [YAML](../kubernetes/memory-deployment.yaml) | [YAML](../kubernetes/memory-service.yaml) | 30082 | http://150.165.85.77:18002/health |
| I/O | `arthuurvidaal/poi-io:atividade4` | [YAML](../kubernetes/io-deployment.yaml) | [YAML](../kubernetes/io-service.yaml) | 30083 | http://150.165.85.77:18003/health |

```bash
kubectl apply -f kubernetes/
kubectl get deployments,pods,services -n poi-atividade5
bash scripts/validar-cluster.sh
bash scripts/testar-aplicacoes.sh
```

### Resultados

- Três Pods `1/1 Running`; três Deployments com rollout concluído.
- CPU: `/primos?limite=10000` → **1229** números primos.
- Memória: `/memoria?tamanho_mb=10` → `verificacao=2561`.
- I/O: `/arquivo?tamanho_mb=1&operacoes=1` → 1.048.576 bytes escritos e lidos; `verificacao=ok`.
- Octavia: **9/9 testes públicos `/health` bem-sucedidos**.
- Pós-reboot: Minikube `Ready` e quatro serviços `systemd` habilitados e ativos.

As oito capturas de evidência foram incorporadas no relatório Word/Google Docs, sem depender de imagens hospedadas no GitHub.
