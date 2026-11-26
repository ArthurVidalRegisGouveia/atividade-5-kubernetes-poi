# Infraestrutura Kubernetes

**Grupo:** 23  
**Alunos:** Arthur Vidal Regis Gouveia; Pedro Henriques Barros Pereira  
**Matrículas:** 123110755; 123110565

> **Estado observado em 26/11/2026:** VM OpenStack criada, Minikube de um nó funcional, três APIs implantadas e testadas localmente e via Octavia. Foram **9/9 respostas positivas** nos testes de estabilidade de `/health` pelo endereço público. O usuário confirmou que o teste de recuperação após reinicializar a VM foi bem-sucedido, incluindo as verificações de serviços e aplicações. Permanecem eventuais evidências visuais, se exigidas.

## Configuração da VM e ambiente da Cloud

### Ambiente administrativo e autenticação

A administração do OpenStack LSD foi realizada a partir de uma VDI Ubuntu em Oracle VirtualBox no Windows. O encaminhamento NAT da VDI permite SSH a partir do PowerShell:

```powershell
ssh -p 2223 osboxes@127.0.0.1
```

Na VDI (`osboxes`), o arquivo `~/provisionamento-openrc.sh` é carregado com `source` para autenticar no projeto `Provisionamento`. Credenciais, tokens, arquivo RC e chave SSH privada não foram versionados.

A quota original estava esgotada (96/96 vCPUs e 196608/196608 MiB de RAM). Após intervenção do administrador, passou para **112 vCPUs e 229376 MiB de RAM**, com 96 vCPUs e 196608 MiB utilizados no momento da verificação, permitindo o provisionamento.

### VM implantada

- **Nome:** `vm-arthur-pedro-k8s`.
- **UUID:** `2efda93b-1f22-4bfa-bd5a-9b750b5b44b5`.
- **Imagem:** `ubuntu-24.04`; sistema inicializado como Ubuntu 24.04.3 LTS.
- **Flavor:** `general.large` — 4 vCPUs, 8192 MiB de RAM e 20 GB de disco nominal.
- **Rede:** `provider`, sub-rede `provider-sub` (`10.5.8.0/22`); IP privado `10.5.10.123`.
- **Security group:** `sg-arthur-pedro-poi`.
- **Keypair:** `arthur-pedro-k8s` (ED25519); chave privada permanece na VDI em `~/.ssh/arthur-pedro-k8s`.
- **Estado observado:** `ACTIVE`, inicialização concluída pelo `cloud-init`, usuário SSH `ubuntu`.

O acesso SSH privado direto da VDI para `10.5.10.123:22` não funcionou. Foi reaproveitado **somente o listener SSH do grupo** no Octavia, pela porta pública `22022`, com novo membro `10.5.10.123:22`. O membro SSH antigo (`10.5.9.10:22`) foi removido depois de confirmar o acesso e a impressão digital ED25519 da nova VM.

```bash
# Na VDI, após autenticar no OpenStack:
ssh -i ~/.ssh/arthur-pedro-k8s -o IdentitiesOnly=yes -p 22022 ubuntu@150.165.85.77
```

O volume Cinder antigo de 1 GiB não foi conectado à nova VM; não foi necessário para o projeto.

### Balanceador Octavia e segurança

- **Load Balancer compartilhado:** `poi-atividades`, UUID `57c2b14a-b746-4f34-8719-d0627e409609`.
- **VIP privado:** `10.5.8.242`; **IP público associado:** `150.165.85.77`.
- **Portas públicas do grupo:** SSH 22022; CPU 18001; memória 18002; I/O 18003.
- **Situação observada:** `provisioning_status=ACTIVE`, mas `operating_status=ERROR` no objeto compartilhado. Não foi determinada a causa global, e não foram alterados listeners ou pools de outros grupos.

Para as aplicações HTTP, os backends passaram a ser `10.5.10.123:8001`, `10.5.10.123:8002` e `10.5.10.123:8003`. Os membros antigos em `10.5.9.10` foram **desabilitados** (`admin_state_up=False`) nos três pools, preservando o histórico sem excluí-los. O acesso SSH também permanece funcional.

As portas HTTP na VM são restringidas no Security Group a IPs específicos; foi observada a necessidade de acrescentar permissão restrita à origem `10.5.11.192/32`, além da regra anterior para `10.5.11.10/32`. A origem observada no SSH e o sucesso posterior da CPU são indícios operacionais, mas não constituem, isoladamente, prova de toda a topologia do Octavia. Nenhuma porta HTTP foi aberta indiscriminadamente para `0.0.0.0/0`.

## Deploy e configuração do cluster Kubernetes

A nova VM recebeu Docker Engine **29.10.1**, kubectl **1.37.3** e Minikube **1.39.0**. A instalação das dependências foi iniciada pelo script `scripts/instalar-dependencias.sh`; como o binário Minikube ainda não estava disponível após a tentativa inicial, foi instalado separadamente a partir do download oficial.

O cluster foi iniciado com `scripts/iniciar-minikube.sh`, usando driver Docker, 3 vCPUs, 6144 MiB de RAM e parâmetro de disco de 12 GiB, runtime containerd. O Kubernetes do nó reportou a versão **v1.37.0**, IP interno `192.168.49.2`, sistema do nó Minikube Debian 12 e runtime `containerd://2.3.4`.

O nó apareceu inicialmente `NotReady` durante a inicialização, mas evoluiu para **`Ready`**. O comando `minikube status` confirmou host, kubelet e apiserver `Running`, além de kubeconfig configurado. O armazenamento raiz da VM apresentava cerca de **12 GB livres** após instalação e criação dos workloads.

O cluster e os Services Kubernetes foram validados com:

```bash
minikube status
kubectl get nodes -o wide
bash scripts/validar-cluster.sh
```

**Exposição de rede:** como os NodePorts no nó Minikube com driver Docker não são automaticamente publicados no IP da VM OpenStack, foi adotado um encaminhamento na VM por `kubectl port-forward` para cada Service. Os processos estão supervisionados pelos serviços `systemd`:

- `poi-cpu-forward.service`: `10.5.10.123:8001` → `service/poi-cpu:8001`.
- `poi-memory-forward.service`: `10.5.10.123:8002` → `service/poi-memory:8002`.
- `poi-io-forward.service`: `10.5.10.123:8003` → `service/poi-io:8003`.

`systemctl is-active` retornou `active` para os três serviços; `curl` no IP privado retornou `{"status":"ok"}` em todas as portas; o `journalctl` confirmou a abertura dos encaminhamentos. Os serviços estão habilitados para inicialização do Ubuntu e possuem política `Restart=always`, e foi configurado o serviço `poi-minikube.service` para iniciar o cluster após o Docker, aguardar o nó ficar `Ready` e permitir a inicialização ordenada dos encaminhamentos HTTP. **Após reiniciar a VM, o usuário confirmou que as verificações de recuperação foram bem-sucedidas.**

## Deploy das Aplicações

### Manifestos e arquitetura

Foram aplicados sete manifestos Kubernetes: um Namespace `poi-atividade5`, três Deployments (uma réplica por aplicação) e três Services `NodePort`.

| Aplicação | Imagem | Deployment / Service | Porta do serviço | NodePort |
| --- | --- | --- | ---: | ---: |
| CPU-bound | `arthuurvidaal/poi-cpu:atividade4` | `poi-cpu` | 8001 | 30081 |
| Memory-bound | `arthuurvidaal/poi-memory:atividade4` | `poi-memory` | 8002 | 30082 |
| I/O-bound | `arthuurvidaal/poi-io:atividade4` | `poi-io` | 8003 | 30083 |

Os Deployments foram escolhidos para reconciliação do número de réplicas e atualizações declarativas. Configuram requests/limits de recursos, `livenessProbe` e `readinessProbe` em `/health`. A aplicação I/O usa `emptyDir` para dados temporários, sem persistência após exclusão do Pod.

Comandos aplicados:

```bash
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/
kubectl get pods -n poi-atividade5
bash scripts/validar-cluster.sh
bash scripts/testar-aplicacoes.sh
```

Os três Pods chegaram a `1/1 Running` e os três Deployments concluíram `rollout` com sucesso.

### Testes locais dos Services

`scripts/testar-aplicacoes.sh` utilizou `kubectl port-forward` temporário para validar:

| Aplicação | `/health` | Teste funcional | Resultado observado |
| --- | --- | --- | --- |
| CPU | `{"status":"ok"}` | `/primos?limite=10000` | `quantidade_primos=1229` |
| Memory | `{"status":"ok"}` | `/memoria?tamanho_mb=10` | `verificacao=2561` |
| I/O | `{"status":"ok"}` | `/arquivo?tamanho_mb=1&operacoes=1` | `bytes_escritos=1048576`, `bytes_lidos=1048576`, `verificacao=ok` |

Os sete manifestos também haviam passado pela verificação offline em `scripts/validar-manifestos-offline.py`, que retornou `OK: 7 manifestos e invariantes do projeto verificados offline.`.

### Testes externos pelo Octavia

A partir da VDI, foram realizadas requisições HTTP ao IP público `150.165.85.77` nas portas do grupo:

| Aplicação | Endpoint `/health` público | Evidência |
| --- | --- | --- |
| CPU | `http://150.165.85.77:18001/health` | HTTP 200, `{"status":"ok"}` |
| Memory | `http://150.165.85.77:18002/health` | `{"status":"ok"}` |
| I/O | `http://150.165.85.77:18003/health` | HTTP 200, `{"status":"ok"}` |

Os três endpoints funcionais também responderam pelo Octavia, com resultados:

- CPU `/primos?limite=10000` → `quantidade_primos=1229`;
- Memory `/memoria?tamanho_mb=10` → `verificacao=2561`;
- I/O `/arquivo?tamanho_mb=1&operacoes=1` → `bytes_escritos=1048576`, `bytes_lidos=1048576`, `bytes_processados=2097152`, `verificacao=ok`.

Ao final, foram repetidas **três requisições `/health` em cada uma das três portas públicas: 9 de 9 testes bem-sucedidos**. Foram confirmados `admin_state_up=False` nos membros HTTP antigos de CPU, Memory e I/O.

### Pontos ainda pendentes

1. Registrar capturas de tela/evidências visuais, caso exigidas no formato final de entrega.
2. Revisar se a configuração `kubectl port-forward` supervisionada por `systemd` atende aos critérios de disponibilidade e operação esperados na atividade; esse método encaminha ao Pod selecionado e pode requerer reconexão quando ele for substituído.
3. Manter o balanceador compartilhado e os demais grupos intactos; o estado global `operating_status=ERROR` permanece sem diagnóstico conclusivo, apesar dos testes externos positivos.

### Verificação após reinicialização da VM

Foi configurado `poi-minikube.service` (`systemd`) para executar `minikube start` com driver Docker e aguardar `kubectl wait --for=condition=Ready node/minikube`. Os três serviços de port-forward foram associados à dependência de inicialização do Minikube. A validação de sintaxe `systemd-analyze verify` não retornou erro, e os quatro serviços foram confirmados `enabled`.

Após o reboot controlado, a saída de `minikube status` reportou host, kubelet e apiserver como `Running` e kubeconfig `Configured`; `kubectl get nodes -o wide` mostrou `minikube Ready`, Kubernetes v1.37.0. O usuário confirmou que as verificações adicionais do serviço de inicialização, Pods, encaminhamentos e endpoints privados e públicos também passaram. As saídas completas desses testes adicionais não foram transcritas na conversa, de modo que são registradas como confirmação informada pelo operador, e não como logs integrais anexados.
