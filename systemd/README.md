# Inicialização automática e port-forward via systemd

O ambiente efetivamente testado na VM OpenStack contém quatro serviços habilitados e ativos:

- `poi-minikube.service`
- `poi-cpu-forward.service`
- `poi-memory-forward.service`
- `poi-io-forward.service`

A captura [05-systemd.png](../evidencias/05-systemd.png) comprova a habilitação e atividade após reinicialização da VM. Os encaminhamentos de aplicações utilizam o IP privado `10.5.10.123` e as portas `8001`, `8002` e `8003`.

## Proveniência e limitação importante

Os arquivos em [exemplos/](exemplos/) são **modelos reconstruídos a partir da arquitetura documentada**, e **não** extrações verificadas dos arquivos presentes em `/etc/systemd/system/` na VM. A VM de produção não foi alterada ao publicar este diretório.

**Não copie esses modelos por cima das unidades existentes**, pois poderão existir ajustes específicos na VM, como caminhos dos binários, dependências via drop-ins, variáveis ou ordem de inicialização. O ideal para documentar os artefatos exatos é exportar e revisar os arquivos reais da VM.

## Como obter a configuração real para conferência

Dentro da **VM Kubernetes** (prompt `ubuntu@vm-arthur-pedro-k8s`):

```bash
for unit in poi-minikube poi-cpu-forward poi-memory-forward poi-io-forward; do
  echo "=== $unit.service ==="
  sudo systemctl cat "$unit.service"
done
```

Esse comando mostra as unidades e os possíveis *drop-ins*. Confira se há credenciais ou segredos antes de publicar qualquer saída.

Para obter apenas os caminhos das unidades principais:

```bash
systemctl show -p FragmentPath -p DropInPaths \
  poi-minikube.service poi-cpu-forward.service \
  poi-memory-forward.service poi-io-forward.service
```

Os modelos em `exemplos/` foram escritos para ilustrar a lógica, **não como instalação automatizada validada**.
