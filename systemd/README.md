# Configurações reais de inicialização automática via systemd

| Serviço | Arquivo instalado na VM | Cópia no repositório |
| --- | --- | --- |
| Inicialização do cluster | `/etc/systemd/system/poi-minikube.service` | [poi-minikube.service](poi-minikube.service) |
| Encaminhamento da API CPU | `/etc/systemd/system/poi-cpu-forward.service` | [poi-cpu-forward.service](poi-cpu-forward.service) |
| Encaminhamento da API Memória | `/etc/systemd/system/poi-memory-forward.service` | [poi-memory-forward.service](poi-memory-forward.service) |
| Encaminhamento da API I/O | `/etc/systemd/system/poi-io-forward.service` | [poi-io-forward.service](poi-io-forward.service) |

## Como funcionam

- `poi-minikube.service` inicia o Minikube com driver Docker, 3 vCPUs, 6144 MiB de RAM, disco 12 GiB e runtime containerd; aguarda o nó ficar `Ready`.
- `poi-cpu-forward.service` publica `service/poi-cpu:8001` no endereço `10.5.10.123:8001`.
- `poi-memory-forward.service` publica `service/poi-memory:8002` no endereço `10.5.10.123:8002`.
- `poi-io-forward.service` publica `service/poi-io:8003` no endereço `10.5.10.123:8003`.
- Os três encaminhamentos reiniciam automaticamente se o processo terminar (`Restart=always`).

A captura [05-systemd.png](../evidencias/05-systemd.png) registra quatro unidades `enabled` e quatro unidades `active` após reboot controlado.

## Observação sobre dependências

Os serviços foram observados funcionando depois de reiniciar a VM, mas iniciar uma aplicação antes do API Server ficar disponível é um risco mitigado parcialmente por `Restart=always`; não há garantia formal de ordenação entre essas unidades nos arquivos acima.

## Conferência sem alterar o ambiente

Na VM Kubernetes:

```bash
sudo systemctl cat \
  poi-minikube.service \
  poi-cpu-forward.service \
  poi-memory-forward.service \
  poi-io-forward.service

systemctl is-enabled \
  poi-minikube.service poi-cpu-forward.service \
  poi-memory-forward.service poi-io-forward.service

systemctl is-active \
  poi-minikube.service poi-cpu-forward.service \
  poi-memory-forward.service poi-io-forward.service
```

Estes arquivos servem para **documentação e reprodução controlada**. Sua inclusão no GitHub não altera as unidades em execução na VM. Os modelos hipotéticos anteriormente colocados em `systemd/exemplos/` foram removidos para evitar confusão com os arquivos reais.
