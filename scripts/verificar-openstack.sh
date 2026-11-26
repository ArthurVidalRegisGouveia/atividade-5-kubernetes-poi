#!/usr/bin/env bash
set -euo pipefail
# Executar APENAS na VDI Ubuntu autenticada com o OpenStack RC.
# Somente leitura: nao cria, altera nem exclui recursos.
command -v openstack >/dev/null || { echo "openstack CLI ausente" >&2; exit 1; }
echo "== Projeto autenticado =="
openstack token issue -f value -c expires
echo
echo "== Quota de computacao =="
openstack limits show --absolute | grep -E 'maxTotalCores|maxTotalRAMSize|totalCoresUsed|totalRAMUsed|totalInstancesUsed'
echo
echo "== Flavor e imagem =="
openstack flavor show general.large -c name -c vcpus -c ram -c disk
openstack image show ubuntu-24.04 -c name -c status
echo
echo "== Rede, seguranca e chave =="
openstack network show provider -c id -c name
openstack security group show sg-arthur-pedro-poi -c id -c name
openstack keypair show arthur-pedro-k8s -c name -c fingerprint
echo
echo "== VM planejada (vazio = ainda nao existe) =="
openstack server list --name vm-arthur-pedro-k8s
echo
echo "== Octavia do grupo (somente consulta) =="
openstack loadbalancer show 57c2b14a-b746-4f34-8719-d0627e409609 \
  -c id -c name -c provisioning_status -c operating_status -c vip_address
echo "Nao altere recursos compartilhados; confirme a quota antes de provisionar."
