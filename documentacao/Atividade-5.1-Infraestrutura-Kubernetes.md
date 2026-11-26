# Infraestrutura Kubernetes

**Grupo:** [preencher]  
**Alunos:** Arthur [nome completo] e Pedro Henriques Barros Pereira  
**Matrículas:** [preencher]

## Configuração da VM e ambiente da Cloud

O projeto OpenStack utilizado é `Provisionamento`. A imagem prevista é `ubuntu-24.04` e o flavor é `general.large` (4 vCPUs e 8192 MiB de RAM). A chave pública `arthur-pedro-k8s` foi registrada no OpenStack.

**Situação:** na última verificação, a quota do projeto registrava 96/96 vCPUs e 196608/196608 MiB de RAM. A criação da VM Kubernetes ainda não foi executada. Adicionar comandos, saídas, ID, IP e capturas de tela depois do provisionamento.

## Deploy e configuração do cluster Kubernetes

**Pendente.** Documentar a instalação do Docker, `kubectl` e Minikube, o driver utilizado, os comandos de inicialização e a validação de nó e componentes.

## Deploy das Aplicações

Os manifestos estão em `kubernetes/`, com um Deployment e um Service NodePort para cada aplicação. A escolha de Deployment permite manter o número desejado de Pods e realizar atualizações controladas; `emptyDir` armazena apenas dados temporários da aplicação I/O.

**Pendente.** Registrar `kubectl apply`, Pods prontos, verificações `/health`, configuração de encaminhamento da rede Minikube para a VM, pools do Octavia e testes pelo IP público.
