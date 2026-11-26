# Roteiro de execucao — somente apos liberacao de quota

> **STATUS: NAO EXECUTADO.** Os comandos sao uma referencia para a futura VM. Nao execute criacoes enquanto a quota nao for suficiente. A nuvem e o balanceador sao compartilhados.

## 0. Ambientes corretos

- **Windows PowerShell**: Git local, navegador e SSH ate a VDI, via `ssh -p 2223 osboxes@127.0.0.1`.
- **VDI Ubuntu/VirtualBox**: autenticacao OpenStack (source do RC), consultas e provisionamento.
- **Nova VM Ubuntu no OpenStack**: Docker, kubectl, Minikube, aplicacao e testes.
- Nunca versionar `*openrc*`, senhas, tokens ou chaves SSH privadas.

## 1. Antes da criacao — na VDI

```bash
source ~/provisionamento-openrc.sh
bash ~/atividade-5-kubernetes-poi/scripts/verificar-openstack.sh
```

Confirmar `maxTotalCores - totalCoresUsed >= 4`, `maxTotalRAMSize - totalRAMUsed >= 8192`, quantidade de instancias e capacidade efetiva. Se ainda houver bloqueio, parar e avisar o professor/administrador. O projeto e compartilhado.

## 2. Criar a VM — apenas apos conferencia e liberacao da quota

```bash
openstack server create \
  --image ubuntu-24.04 \
  --flavor general.large \
  --network provider \
  --key-name arthur-pedro-k8s \
  --security-group sg-arthur-pedro-poi \
  vm-arthur-pedro-k8s

openstack server show vm-arthur-pedro-k8s \
  -c id -c status -c addresses -c flavor -c image -c key_name
```

A rede provider fornece IP privado (ainda desconhecido). Conferir o security group e a rota SSH antes de conectar; a presenca da chave no OpenStack nao garante caminho de rede. Usar somente nossa chave privada `~/.ssh/arthur-pedro-k8s` na VDI e o usuario indicado pela imagem Ubuntu (normalmente `ubuntu`). **Nao** publicar a chave nem assumir que o antigo encaminhamento Octavia esta funcional. A reutilizacao do listener 22022 exige primeiro conferir o pool e atualizar somente membro do nosso grupo.

## 3. Na nova VM Ubuntu — depois de confirmar SSH

```bash
git clone https://github.com/ArthurVidalRegisGouveia/atividade-5-kubernetes-poi.git
cd atividade-5-kubernetes-poi
bash scripts/instalar-dependencias.sh
```

Sair e entrar novamente na sessao SSH para o grupo docker ter efeito. Depois:

```bash
cd ~/atividade-5-kubernetes-poi
docker info >/dev/null
bash scripts/iniciar-minikube.sh
kubectl get nodes -o wide
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/
bash scripts/validar-cluster.sh
bash scripts/testar-aplicacoes.sh
```

Se houver erros, parar e investigar os Pods (`kubectl -n poi-atividade5 describe pod ...`, `kubectl -n poi-atividade5 logs deployment/poi-cpu`). Nao registrar como concluido sem saidas reais.

## 4. Testes de rede e Octavia — sem tocar em recursos de outros grupos

O driver Docker do Minikube coloca o no Kubernetes em rede de container. As portas NodePort 30081/30082/30083 **nao sao automaticamente acessiveis no IP privado da VM**. Primeiro validar com `kubectl port-forward` (script local). Depois identificar `minikube ip`, a rota e a conectividade entre VM host e o no, selecionando um metodo de exposicao permanente da VM (por exemplo proxy TCP gerenciado por systemd com regras restritas), **apos testes reais**. Nao configurar pools apontando para a VM ate esta responder a partir da rede do balanceador.

Listener e pool historicos do grupo:
| Uso | Listener Octavia ID | Porta publica | Pool ID |
| --- | --- | --- | --- |
| SSH | `4b4b61d4-81af-46a6-a0fb-b8fee82d5493` | 22022 | `f066db26-7733-418c-be4d-397a36eaeb74` |
| CPU | `cd29298e-9a56-4c5f-800e-2747bc8e42f4` | 18001 | `48c674d4-dc2c-4589-8ea1-7faef39f3da4` |
| Memory | `0431f43c-9d2b-40ed-b4da-bc210cddeb07` | 18002 | `2a9f5bf7-a0cd-4203-b58a-d98a90c35024` |
| I/O | `6c5cba08-78e5-4360-a9a6-de6701aa3e23` | 18003 | `c35b149a-3002-4136-aeaf-30696da03f71` |

Balanceador `57c2b14a-b746-4f34-8719-d0627e409609` — VIP privado `10.5.8.242`, floating IP historico `150.165.85.77`. Estado observado: provisioning ACTIVE, operating ERROR. **A causa do ERROR nao foi comprovada.** O balanceador possui listeners de muitos grupos, portanto nunca altere o proprio LB ou recursos nao identificados como nossos.

Consultar na VDI com:
```bash
openstack loadbalancer show 57c2b14a-b746-4f34-8719-d0627e409609 -c provisioning_status -c operating_status
openstack loadbalancer pool show 48c674d4-dc2c-4589-8ea1-7faef39f3da4
openstack loadbalancer member list 48c674d4-dc2c-4589-8ea1-7faef39f3da4
openstack loadbalancer member list 2a9f5bf7-a0cd-4203-b58a-d98a90c35024
openstack loadbalancer member list c35b149a-3002-4136-aeaf-30696da03f71
```

### Inventario confirmado dos membros antigos em 26/11/2026

Os quatro comandos `openstack loadbalancer member list <POOL_ID>` retornaram **um membro por pool**, todos com `provisioning_status=ACTIVE`, `operating_status=NO_MONITOR`, peso 1 e o endereco privado antigo `10.5.9.10`:

| Servico | Pool ID | Member ID | Endereco antigo |
| --- | --- | --- | --- |
| SSH | `f066db26-7733-418c-be4d-397a36eaeb74` | `0f1ff044-b6fc-435a-a442-a4ae690b81b1` | `10.5.9.10:22` |
| CPU | `48c674d4-dc2c-4589-8ea1-7faef39f3da4` | `5c2b679f-9c06-4bf4-98de-59ce7fb6aca8` | `10.5.9.10:8001` |
| Memory | `2a9f5bf7-a0cd-4203-b58a-d98a90c35024` | `a3606ba9-924f-40b5-ae09-79ff445402fd` | `10.5.9.10:8002` |
| I/O | `c35b149a-3002-4136-aeaf-30696da03f71` | `ba5cb6fd-4195-46f6-86fa-5856bde6ef8f` | `10.5.9.10:8003` |

`NO_MONITOR` nao comprova que o backend esta saudavel. Estes membros ainda nao foram alterados. O futuro encaminhamento do Octavia pode utilizar portas de proxy na VM (por exemplo, 8001/8002/8003) somente se sua conectividade para os Services Kubernetes for realmente implementada e testada. Nao assumir que NodePorts 30081/30082/30083 funcionam no IP da VM quando Minikube utiliza driver Docker.

Os ajustes de membros (novo IP privado e portas comprovadamente acessiveis) so devem ocorrer depois de registrar os membros antigos e confirmar que esses pools sao exclusivamente nossos. Nao existe ainda comando seguro de alteracao predefinido porque o IP, a topologia e a exposicao da nova VM nao foram testados.

## 5. Evidencias para a demonstracao

Guardar: `openstack server show`, `minikube status`, `kubectl get nodes -o wide`, `kubectl -n poi-atividade5 get deploy,pod,svc -o wide`, saida de `scripts/testar-aplicacoes.sh`, testes externos HTTP `/health`, `/docs` e endpoints funcionais no IP publico, e estado final dos membros/pools. O relatorio so deve descrever resultados observados.
