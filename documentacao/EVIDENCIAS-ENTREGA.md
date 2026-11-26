# Evidências para entrega — Atividade 5.1

**Grupo 23 — Infraestrutura Kubernetes (POI)**

Este roteiro serve para coletar capturas e comprovar a atividade. **Não contém campos de assinatura nem assinaturas pessoais ou digitais.** A infraestrutura já foi implantada e testada; as imagens abaixo ainda devem ser capturadas pelo grupo.

## Na VDI Ubuntu administrativa (`osboxes`)

Caso necessário, autenticar no OpenStack com `source ~/provisionamento-openrc.sh`. Não publicar senhas, tokens ou o arquivo RC.

### 01 — VM OpenStack em execução

```bash
openstack server show vm-arthur-pedro-k8s -c name -c status -c addresses -c flavor -c image
```

Capturar a VM `ACTIVE`, IP privado `10.5.10.123` e flavor `general.large`.

### 02 — APIs acessíveis pelo Octavia

```bash
for porta in 18001 18002 18003; do
  echo "=== Porta pública $porta ==="
  curl --noproxy '*' -fsS --max-time 15 "http://150.165.85.77:${porta}/health"
  echo
done
```

Resultado observado anteriormente: três respostas `{"status":"ok"}`. Os nove testes consecutivos anteriores (3 por porta) também foram bem-sucedidos.

### 03 — Testes funcionais externos

```bash
curl --noproxy '*' -fsS --max-time 30 'http://150.165.85.77:18001/primos?limite=10000'; echo
curl --noproxy '*' -fsS --max-time 30 'http://150.165.85.77:18002/memoria?tamanho_mb=10'; echo
curl --noproxy '*' -fsS --max-time 30 'http://150.165.85.77:18003/arquivo?tamanho_mb=1&operacoes=1'; echo
```

Resultados observados anteriormente: 1229 primos, memória com `verificacao=2561` e I/O com `verificacao=ok`.

## Na VM OpenStack Kubernetes (`ubuntu`)

Conectar **a partir da VDI**:

```bash
ssh -i ~/.ssh/arthur-pedro-k8s -o IdentitiesOnly=yes -p 22022 ubuntu@150.165.85.77
```

### 04 — Cluster Minikube e nó Ready

```bash
minikube status
kubectl get nodes -o wide
```

Capturar `host/kubelet/apiserver Running` e o nó `minikube Ready`.

### 05 — Deployments, Pods e Services

```bash
kubectl -n poi-atividade5 get deployments,pods,services -o wide
```

Capturar os três Deployments disponíveis, três Pods `1/1 Running` e Services NodePort 30081, 30082 e 30083.

### 06 — Serviços persistentes e recuperação após reinicialização

```bash
systemctl is-enabled poi-minikube.service poi-cpu-forward.service poi-memory-forward.service poi-io-forward.service
systemctl is-active poi-minikube.service poi-cpu-forward.service poi-memory-forward.service poi-io-forward.service
systemctl status poi-minikube.service --no-pager
```

O serviço `poi-minikube.service` pode aparecer `active (exited)` por ser `Type=oneshot`. O operador confirmou que o cluster, os serviços e as APIs se recuperaram após reiniciar a VM.

## Organização sugerida das capturas

- `01-vm-openstack-active.png`
- `02-apis-health-publico.png`
- `03-testes-funcionais-publicos.png`
- `04-minikube-ready.png`
- `05-deployments-pods-services.png`
- `06-systemd-pos-reboot.png`

As imagens não estão anexadas automaticamente. Capturar e revisar antes de publicar. **Não incluir chaves SSH privadas, tokens, credenciais, dados sensíveis ou assinaturas.** Nunca versionar `~/.kube/config` nem `provisionamento-openrc.sh`.

## Checklist de entrega

- [x] VM Ubuntu OpenStack criada
- [x] Cluster Minikube de um nó e Deployments testados
- [x] Três APIs funcionais localmente e por Octavia
- [x] Nove de nove testes públicos `/health` aprovados
- [x] Serviços systemd e teste pós-reboot confirmados
- [ ] Capturas coletadas e revisadas
- [ ] Comparação final com o enunciado oficial da atividade

Consultar também `documentacao/Atividade-5.1-Infraestrutura-Kubernetes.md` para o relatório detalhado. O balanceador Octavia é compartilhado; seu estado operacional global `ERROR` persiste apesar dos testes externos positivos. Não alterar recursos de outros grupos.
