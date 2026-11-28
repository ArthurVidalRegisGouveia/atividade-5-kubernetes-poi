import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parent
SAIDA = BASE / "graficos"
SAIDA.mkdir(exist_ok=True)

with (BASE / "resumo-experimentos.csv").open(
    encoding="utf-8", newline=""
) as arquivo:
    dados = list(csv.DictReader(arquivo))

cenarios = [r for r in dados if r["aplicacao"] == "io"]

rotulos = []
taxas_sucesso = []
taxas_503 = []

for r in cenarios:
    politica = r["politica"]

    if r["tipo"] == "hpa":
        rotulo = f"HPA {politica}%"
    elif politica == "Off":
        rotulo = "VPA Off"
    else:
        rotulo = "VPA Auto"

    sucesso = int(r["sucessos"])
    erro503 = int(r["http503"])
    outras = int(r["outras_falhas"])
    total = sucesso + erro503 + outras

    rotulos.append(rotulo)
    taxas_sucesso.append(100 * sucesso / total)
    taxas_503.append(100 * erro503 / total)

fig, ax = plt.subplots(figsize=(10, 6))

posicoes = range(len(rotulos))

ax.bar(
    posicoes,
    taxas_sucesso,
    label="HTTP 200",
    color="#0f766e",
)

ax.bar(
    posicoes,
    taxas_503,
    bottom=taxas_sucesso,
    label="HTTP 503",
    color="#dc2626",
)

for i, (sucesso, erro) in enumerate(
    zip(taxas_sucesso, taxas_503)
):
    ax.text(
        i,
        sucesso + erro / 2,
        f"{erro:.2f}%",
        ha="center",
        va="center",
        fontsize=11,
        fontweight="bold",
        color="white" if erro >= 10 else "black",
    )

ax.set_xticks(list(posicoes))
ax.set_xticklabels(rotulos)
ax.set_ylim(0, 105)
ax.set_ylabel("Percentual das tentativas (%)")
ax.set_title(
    "Atividade 5.2 — Respostas HTTP da IO-bound",
    fontsize=15,
    fontweight="bold",
)
ax.legend(loc="upper right")
ax.grid(axis="y", alpha=0.2)
ax.set_axisbelow(True)

ax.text(
    0.5,
    -0.14,
    "VPA Off: 1 réplica | VPA Auto: 2 réplicas",
    transform=ax.transAxes,
    ha="center",
    fontsize=10,
)

fig.tight_layout()

destino = SAIDA / "http-io-comparativo.png"
fig.savefig(destino, dpi=160, bbox_inches="tight")
plt.close(fig)

print(f"Gerado: {destino}")
