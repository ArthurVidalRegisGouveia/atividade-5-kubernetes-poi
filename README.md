# Atividade 5.1 — Infraestrutura Kubernetes

**Grupo 23 — UFCG / POI**  
Arthur Vidal Regis Gouveia — 123110755  
Pedro Henriques Barros Pereira — 123110565

Três APIs FastAPI executadas em Kubernetes (Minikube) numa VM Ubuntu 24.04 do OpenStack LSD, com acesso externo pelo Octavia.

## Ambiente

- **VM:** `vm-arthur-pedro-k8s`
- **ID:** `2efda93b-1f22-4bfa-bd5a-9b750b5b44b5`
- **Flavor:** `general.large` (4 vCPUs, 8 GiB RAM)
- **IP privado:** `10.5.10.123`
- **Cluster:** Minikube, um nó `Ready`
- **Namespace:** `poi-atividade5`

## Aplicações

| Aplicação | Docker Hub | Deployment | Service | URL pública |
| --- | --- | --- | --- | --- |
| CPU | [poi-cpu](https://hub.docker.com/r/arthuurvidaal/poi-cpu) | [YAML](kubernetes/cpu-deployment.yaml) | [YAML](kubernetes/cpu-service.yaml) | [API](http://150.165.85.77:18001/health) |
| Memória | [poi-memory](https://hub.docker.com/r/arthuurvidaal/poi-memory) | [YAML](kubernetes/memory-deployment.yaml) | [YAML](kubernetes/memory-service.yaml) | [API](http://150.165.85.77:18002/health) |
| I/O | [poi-io](https://hub.docker.com/r/arthuurvidaal/poi-io) | [YAML](kubernetes/io-deployment.yaml) | [YAML](kubernetes/io-service.yaml) | [API](http://150.165.85.77:18003/health) |

As três imagens usam a tag `atividade4`. Os manifestos utilizam Deployments e Services `NodePort`. O tráfego do Octavia chega aos Services por encaminhamentos `kubectl port-forward` supervisionados pelo `systemd`.

## Verificação

Na VM Kubernetes:

```bash
minikube status
kubectl get nodes
kubectl get deployments,pods,services -n poi-atividade5
bash scripts/validar-cluster.sh
bash scripts/testar-aplicacoes.sh
```

Em 26/11/2026, os três Pods estavam `Running`, os Deployments concluíram o rollout e os testes funcionais passaram. Foram obtidas **9/9 respostas positivas** nas consultas públicas de `/health`; os serviços e o cluster também foram verificados após reinicialização.

## Estrutura

- [`kubernetes/`](kubernetes/) — sete manifestos YAML.
- [`scripts/`](scripts/) — instalação e validação.
- [`documentacao/Atividade-5.1-Infraestrutura-Kubernetes.md`](documentacao/Atividade-5.1-Infraestrutura-Kubernetes.md) — resumo técnico.

## Código-fonte das aplicações e configuração de inicialização

- [Código das três APIs](aplicacoes/README.md) — cópias dos arquivos `main.py` publicados originalmente em [atividade-2-poi](https://github.com/ArthurVidalRegisGouveia/atividade-2-poi). 
- [Configurações reais dos serviços systemd](systemd/README.md) — quatro unidades transcritas da saída de `sudo systemctl cat` executada na VM.
- [Evidências visuais](evidencias/) — oito capturas validadas, incluindo cluster, Deployments, rollouts, serviços e testes pelo Octavia.


## Atividade 5.2 — Autoscaling com HPA e VPA

Em 28/11/2026 foram executados 12 cenarios experimentais:
seis com HPA e seis com VPA, envolvendo as aplicacoes CPU-bound,
Memory-bound e IO-bound.

- HPA: politicas de utilizacao-alvo de 50% e 75%.
- VPA: modos `Off` e `InPlaceOrRecreate`.
- Duracao nominal de cada teste: 120 segundos.
- Resultados: metricas, logs, eventos e nove graficos PNG.

**Relatorio completo:**
[Atividade 5.2 — Autoscaling HPA e VPA](documentacao/Atividade-5.2-Autoscaling-HPA-VPA.md).

**Artefatos:** [atividade-5.2/](atividade-5.2/).

O desempenho observado deve ser interpretado considerando as
limitacoes metodologicas descritas no relatorio, especialmente
a diferenca no numero de replicas entre os testes VPA.
