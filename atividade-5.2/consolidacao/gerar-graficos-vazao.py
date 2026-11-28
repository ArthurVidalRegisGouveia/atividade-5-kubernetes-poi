import csv
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parent
ARQUIVO = BASE / "resumo-experimentos.csv"
SAIDA = BASE / "graficos"
SAIDA.mkdir(exist_ok=True)

with ARQUIVO.open(encoding="utf-8", newline="") as arquivo:
    dados = list(csv.DictReader(arquivo))

nomes = {
    "cpu": "CPU-bound",
    "memory": "Memory-bound",
    "io": "IO-bound",
}

def gerar_grafico(tipo):
    registros = [r for r in dados if r["tipo"] == tipo]

    rotulos = []
    valores = []
    cores = []

    for registro in registros:
        aplicacao = nomes[registro["aplicacao"]]
        politica = registro["politica"]

        if politica == "InPlaceOrRecreate":
            politica = "Auto"

        rotulos.append(f"{aplicacao}\n{politica}")
        valores.append(float(registro["vazao_sucessos_req_s"]))
        cores.append("#2563eb" if tipo == "hpa" else "#0f766e")

    fig, ax = plt.subplots(figsize=(12, 6))

    barras = ax.bar(rotulos, valores, color=cores, width=0.65)

    ax.set_title(
        f"Atividade 5.2 — Vazão de sucesso ({tipo.upper()})",
        fontsize=15,
        fontweight="bold",
    )
    ax.set_ylabel("Requisições HTTP 200 por segundo")
    ax.set_ylim(0, max(valores) * 1.22)
    ax.grid(axis="y", alpha=0.25)
    ax.set_axisbelow(True)

    for barra, valor in zip(barras, valores):
        ax.text(
            barra.get_x() + barra.get_width() / 2,
            barra.get_height() + 0.12,
            f"{valor:.2f}",
            ha="center",
            fontsize=10,
        )

    if tipo == "vpa":
        ax.text(
            0.5, -0.19,
            "VPA Off: 1 réplica | VPA Auto: 2 réplicas",
            transform=ax.transAxes,
            ha="center",
            fontsize=10,
        )

    fig.tight_layout()
    destino = SAIDA / f"vazao-{tipo}.png"
    fig.savefig(destino, dpi=160, bbox_inches="tight")
    plt.close(fig)

    print(f"Gerado: {destino}")

gerar_grafico("hpa")
gerar_grafico("vpa")
