# Infraestrutura Kubernetes

**Grupo:** 23  
**Alunos:** Arthur Vidal Regis Gouveia; Pedro Henriques Barros Pereira  
**Matrículas:** 123110755; 123110565

> **Estado em 26/11/2026: preparação efetuada; provisionamento, cluster e testes externos ainda pendentes.** Nenhum resultado posterior foi inventado.

## Configuração da VM e ambiente da Cloud

### Acesso administrativo ao OpenStack

O acesso foi restabelecido utilizando a VDI Ubuntu 22.04 LTS x86_64 fornecida para as atividades anteriores, executada no Oracle VirtualBox em um computador Windows. Uma regra NAT encaminha a porta local 2223/TCP para a porta SSH 22/TCP da VDI. No PowerShell do Windows, o acesso e realizado por:

```powershell
ssh -p 2223 osboxes@127.0.0.1
```

Na VDI, o cliente `openstack 5.8.0` foi autenticado com um arquivo OpenStack RC baixado para o projeto `Provisionamento`. Arquivo RC, senha, token e chave privada **nao sao versionados**.

### Recursos identificados e restricao de quota

- Projeto: `Provisionamento`.
- Imagem prevista: `ubuntu-24.04` (disponivel e ativa).
- Flavor previsto: `general.large`, com **4 vCPUs, 8192 MiB de RAM e disco de 20 GB**.
- Redes disponiveis: `provider` e `public`.
- Grupo de seguranca existente: `sg-arthur-pedro-poi`.
- Chave SSH criada na VDI em `~/.ssh/arthur-pedro-k8s` e chave publica importada ao OpenStack com o nome `arthur-pedro-k8s` (ED25519). A chave privada permanece somente na VDI.
- VM anterior `vm-arthur-pedro-poi`: nao encontrada. Nova VM `vm-arthur-pedro-k8s`: ainda nao criada.
- Volume antigo `volume-arthur-pedro-poi`: 1 GiB, `available`; nao alterado.

Na consulta mais recente informada, a quota compartilhada estava totalmente utilizada: **96/96 vCPUs e 196608/196608 MiB de RAM**. Ha capacidade de contagem de instancias (26/45), mas nao de CPU ou RAM. Assim, ainda nao foi possivel provisionar a VM. Nenhuma VM de outros grupos sera excluida para liberar recursos.

O roteiro de verificacao de quota e recursos, sem mutacoes, consta em `scripts/verificar-openstack.sh`. A criacao futura da VM e descrita em `documentacao/ROTEIRO-PENDENTE-QUOTA.md`.

### Balanceador de carga existente

O Octavia foi consultado apos a instalacao do cliente `python3-octaviaclient` na VDI. O Load Balancer `poi-atividades` (ID `57c2b14a-b746-4f34-8719-d0627e409609`) tem VIP privado `10.5.8.242` associado ao IP publico `150.165.85.77`.

Na consulta observada: `provisioning_status=ACTIVE` e `operating_status=ERROR`. **A causa desse erro nao foi comprovada.** O mesmo balanceador atende diversos grupos; seu objeto global e os listeners dos demais grupos devem permanecer intactos.

Listeners historicamente atribuidos ao nosso grupo: SSH na porta publica `22022`, CPU na `18001`, Memory na `18002` e I/O na `18003`. Os membros historicos apontavam para a VM antiga `10.5.9.10`; so poderao ser corrigidos depois de testar o novo backend. IDs exatos dos nossos pools e listeners estao documentados no roteiro.

## Deploy e configuração do cluster Kubernetes

**Planejado, ainda nao realizado.** A VM Ubuntu 24.04 de 4 vCPUs e 8 GiB executara um cluster de no unico com Minikube, driver Docker. No repositorio ha:

- `scripts/instalar-dependencias.sh`: instala Docker Engine, kubectl e Minikube **na nova VM**;
- `scripts/iniciar-minikube.sh`: inicia Minikube com 3 vCPUs, 6144 MiB e disco virtual de 12 GiB; essa reserva deve ser confirmada contra o disco disponivel e o comportamento do driver;
- `scripts/validar-cluster.sh`: confere o status do Minikube, o no e o rollout dos Deployments;
- `documentacao/ROTEIRO-PENDENTE-QUOTA.md`: sequencia de execucao e verificacao.

Nao executar esses scripts na VDI Ubuntu administrativa. Nao ha no Kubernetes em funcionamento neste momento. Os detalhes de versao, status e evidencias serao adicionados apos executar e conferir cada comando na nova VM.

## Deploy das Aplicações

### Artefatos e justificativa

Foram preparados **sete manifestos** no diretorio `kubernetes/`: um Namespace `poi-atividade5`, tres Deployments e tres Services NodePort.

| Aplicacao | Imagem Docker | Deployment | NodePort planejado |
| --- | --- | --- | --- |
| CPU-bound | `arthuurvidaal/poi-cpu:atividade4` | `poi-cpu` | 30081 |
| Memory-bound | `arthuurvidaal/poi-memory:atividade4` | `poi-memory` | 30082 |
| I/O-bound | `arthuurvidaal/poi-io:atividade4` | `poi-io` | 30083 |

O **Deployment** foi escolhido por permitir manter a replica desejada por ReplicaSet, reiniciar Pods que falham e executar atualizacoes declarativas; nao precisamos de identidade de rede ou armazenamento estavel por Pod, como em um StatefulSet. Cada Deployment configura recursos solicitados/limitados e `livenessProbe` e `readinessProbe` usando `/health`.

A aplicacao I/O utiliza `emptyDir` no caminho `/dados/io-temporarios`, adequado aos arquivos de trabalho descartaveis gerados pelos testes. Os dados nao persistem apos remocao do Pod. O volume Cinder existente nao foi anexado nem e utilizado nesse desenho.

### Verificacoes feitas sem cluster

1. O Docker Hub respondeu a `docker manifest inspect` para as tres imagens: CPU **OK**, Memory **OK**, I/O **OK**. Isso verifica a disponibilidade dos manifestos das imagens, **nao** a execucao dos containers.
2. A VDI Ubuntu usou Python 3 e PyYAML 5.4.1 para analisar os sete arquivos `.yaml`. Todos foram interpretados com sucesso e possuem os campos basicos `apiVersion`, `kind` e `metadata.name`.
3. Foram preparados testes offline adicionais em `scripts/validar-manifestos-offline.py` para conferir nomes, namespace, seletores, imagens, portas, probes e armazenamento temporario. **Esse script foi versionado, mas ainda precisa ser executado e ter sua saida registrada.**
4. O comando `kubectl create --dry-run=client`, mesmo com `--validate=false`, tentou consultar `localhost:8080`, pois a VDI nao possui acesso a um cluster Kubernetes. Isso **nao demonstra defeito nos YAMLs**.

### Validacoes pendentes

Assim que a VM e o Minikube estiverem prontos, aplicar os manifestos, verificar Pods, Services, eventos e rollouts; executar `scripts/testar-aplicacoes.sh` para requisicoes `/health`, `/primos`, `/memoria` e `/arquivo` por meio de Services e `kubectl port-forward`.

**Atencao:** com Minikube no driver Docker, os NodePorts do no containerizado nao sao automaticamente acessiveis pela interface de rede da VM OpenStack. Antes de modificar qualquer membro dos pools compartilhados, sera necessario verificar a conectividade real e estabelecer exposicao confiavel na VM.

Por fim, testar publicamente as APIs pelo endereco Octavia e as portas designadas ao nosso grupo, registrar codigos HTTP e evidencias de navegacao. Essas etapas ainda **nao foram realizadas**.
