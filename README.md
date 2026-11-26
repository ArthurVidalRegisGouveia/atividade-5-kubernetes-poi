# Atividade 5.1 — Infraestrutura Kubernetes (POI)

**Grupo 23:** Arthur Vidal Regis Gouveia (123110755) e Pedro Henriques Barros Pereira (123110565).

## Situação da atividade (26/11/2026)

**Infraestrutura implementada e testada:** VM Ubuntu 24.04 no OpenStack LSD, cluster Minikube de um nó `Ready`, três Deployments e três Services Kubernetes, encaminhamentos HTTP `systemd` e acesso pelo Octavia. Os testes locais funcionais e externos foram bem-sucedidos, inclusive **9/9 requisições públicas `/health`**.

**Recuperação pós-reboot validada:** após configurar `poi-minikube.service` e dependências dos encaminhamentos `systemd`, a VM foi reiniciada; o nó Minikube voltou `Ready`, e o usuário confirmou sucesso nos testes dos serviços e endpoints privados e públicos. Restam revisão final e eventuais capturas de tela para entrega.

## Infraestrutura atual

- VM `vm-arthur-pedro-k8s`, UUID `2efda93b-1f22-4bfa-bd5a-9b750b5b44b5`.
- Ubuntu 24.04.3 LTS, flavor `general.large` (4 vCPUs, 8 GiB RAM, 20 GB de disco).
- Rede `provider`, IP privado `10.5.10.123`, sub-rede `provider-sub`.
- Acesso SSH público via listener Octavia: `150.165.85.77:22022`, usuário `ubuntu`, keypair `arthur-pedro-k8s`.
- Docker 29.10.1, kubectl 1.37.3, Minikube 1.39.0; nó Kubernetes v1.37.0 `Ready`.
- Três serviços de port-forward `systemd`, supervisionando `kubectl port-forward` nas portas privadas 8001, 8002 e 8003.
- Load Balancer Octavia compartilhado UUID `57c2b14a-b746-4f34-8719-d0627e409609`; objeto global com `operating_status=ERROR`, apesar dos testes públicos bem-sucedidos. Não modificar recursos de outros grupos.

## Aplicações

| App | Imagem | Kubernetes Service | NodePort | Endpoint público |
| --- | --- | --- | ---: | --- |
| CPU | `arthuurvidaal/poi-cpu:atividade4` | `poi-cpu:8001` | 30081 | http://150.165.85.77:18001/health |
| Memory | `arthuurvidaal/poi-memory:atividade4` | `poi-memory:8002` | 30082 | http://150.165.85.77:18002/health |
| I/O | `arthuurvidaal/poi-io:atividade4` | `poi-io:8003` | 30083 | http://150.165.85.77:18003/health |

O namespace é `poi-atividade5`. Cada Deployment tem uma réplica, probes de saúde e limites de recursos. A API I/O usa armazenamento temporário `emptyDir`. Os NodePorts do nó Docker não são diretamente expostos no IP da VM; o tráfego externo utiliza serviços `systemd` com `kubectl port-forward`.

Testes funcionais confirmados localmente **e pelo Octavia**:
- `/primos?limite=10000`: 1229 números primos;
- `/memoria?tamanho_mb=10`: `verificacao=2561`;
- `/arquivo?tamanho_mb=1&operacoes=1`: `bytes_escritos=1048576`, `bytes_lidos=1048576`, `verificacao=ok`.

Os membros antigos em `10.5.9.10` dos três pools HTTP estão desabilitados (`admin_state_up=False`); os novos apontam para `10.5.10.123`. Não excluir ou alterar outros membros do balanceador compartilhado.

## Estrutura do repositório

- `kubernetes/`: sete manifestos YAML.
- `scripts/instalar-dependencias.sh`: instala Docker Engine, kubectl e Minikube na VM.
- `scripts/iniciar-minikube.sh`: inicializa o Minikube de um nó, driver Docker.
- `scripts/validar-cluster.sh`: valida nó, serviços e rollouts.
- `scripts/testar-aplicacoes.sh`: testa os endpoints por `kubectl port-forward`.
- `scripts/validar-manifestos-offline.py`: valida sete manifestos sem cluster.
- `scripts/verificar-openstack.sh`: diagnósticos somente leitura na VDI com RC autenticado.
- `documentacao/Atividade-5.1-Infraestrutura-Kubernetes.md`: **relatório completo atualizado com evidências observadas**.
- `documentacao/ROTEIRO-PENDENTE-QUOTA.md`: roteiro histórico usado durante a preparação; a quota já foi ampliada e a VM já foi criada.
- `documentacao/EVIDENCIAS-ENTREGA.md`: roteiro de capturas, comandos de validação e checklist da entrega, sem assinaturas.

## Acesso e manutenção

No PowerShell Windows, conectar à VDI administrativa do VirtualBox:

```powershell
ssh -p 2223 osboxes@127.0.0.1
```

Dentro da VDI (`osboxes`), acessar a VM Kubernetes:

```bash
ssh -i ~/.ssh/arthur-pedro-k8s -o IdentitiesOnly=yes -p 22022 ubuntu@150.165.85.77
```

Dentro da VM Kubernetes, verificar a infraestrutura:

```bash
minikube status
kubectl -n poi-atividade5 get deployments,pods,services
systemctl is-active poi-cpu-forward.service poi-memory-forward.service poi-io-forward.service
```

Testar os serviços publicamente a partir da VDI:

```bash
for porta in 18001 18002 18003; do curl --noproxy '*' -fsS --max-time 15 "http://150.165.85.77:${porta}/health"; echo; done
```

**Segurança:** nunca versionar chave SSH privada, RC do OpenStack, tokens ou senhas; não abrir desnecessariamente as portas HTTP para `0.0.0.0/0`. O grupo de segurança foi ajustado com origem restrita para a conectividade com o Octavia.

**Persistência:** `poi-minikube.service` foi habilitado para inicializar o cluster após Docker; os três serviços HTTP estão habilitados e dependem da inicialização do Minikube. O teste pós-reboot foi confirmado como bem-sucedido pelo operador.
