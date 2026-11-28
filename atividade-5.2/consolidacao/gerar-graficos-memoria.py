import csv
from datetime import datetime
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path(__file__).resolve().parent.parent
RESULTADOS = BASE / "resultados"
SAIDA = BASE / "consolidacao" / "graficos"


def ler(cenario):
    caminho = RESULTADOS / cenario / "metricas.csv"

    with caminho.open(encoding="utf-8", newline="") as arquivo:
        linhas = list(csv.DictReader(arquivo))

    inicio = datetime.fromisoformat(
        linhas[0]["data_utc"].replace("Z", "+00:00")
    )

    for linha in linhas:
        instante = datetime.fromisoformat(
            linha["data_utc"].replace("Z", "+00:00")
        )
        linha["_tempo"] = (instante - inicio).total_seconds()

    return linhas


def memoria_mib(valor):
    if not valor:
        return float("nan")

    if valor.endswith("Mi"):
        return float(valor[:-2])

    if valor.endswith("Gi"):
        return float(valor[:-2]) * 1024

    return float(valor)


def salvar(figura, nome):
    destino = SAIDA / nome
    figura.tight_layout()
    figura.savefig(destino, dpi=160, bbox_inches="tight")
    plt.close(figura)
    print(f"Gerado: {destino}")


def grafico_off():
    cenarios = [
        ("cpu", "CPU-bound", 256),
        ("memory", "Memory-bound", 256),
        ("io", "IO-bound", 128),
    ]

    fig, eixos = plt.subplots(3, 1, figsize=(12, 10))

    for eixo, (app, titulo, memoria_original) in zip(eixos, cenarios):
        linhas = ler(f"vpa-{app}-off")

        tempo = [r["_tempo"] for r in linhas]
        recomendacao = [
            memoria_mib(r["vpa_memoria_recomendada"])
            for r in linhas
        ]

        eixo.plot(
            tempo,
            recomendacao,
            marker=".",
            label="Memória recomendada",
        )

        eixo.plot(
            tempo,
            [memoria_original] * len(tempo),
            linestyle="--",
            label="Memory request original",
        )

        eixo.set_title(titulo)
        eixo.set_ylabel("Memória (MiB)")
        eixo.set_xlabel("Tempo desde o início da coleta (s)")
        eixo.grid(alpha=0.25)
        eixo.legend()

    fig.suptitle(
        "Atividade 5.2 — VPA Off: memória recomendada",
        fontsize=15,
        fontweight="bold",
    )

    salvar(fig, "vpa-off-memoria-recomendada.png")


def grafico_auto():
    cenarios = [
        ("cpu", "CPU-bound"),
        ("memory", "Memory-bound"),
        ("io", "IO-bound"),
    ]

    fig, eixos = plt.subplots(3, 1, figsize=(12, 11))

    for eixo, (app, titulo) in zip(eixos, cenarios):
        linhas = ler(f"vpa-{app}-auto")

        coluna_recomendacao = (
            "vpa_memoria" if app == "cpu"
            else "vpa_memoria_recomendada"
        )

        recomendacoes = {}
        pods = {}

        for linha in linhas:
            tempo = linha["_tempo"]

            recomendacoes[tempo] = memoria_mib(
                linha[coluna_recomendacao]
            )

            pod = linha["pod"]
            pods.setdefault(pod, []).append(
                (
                    tempo,
                    memoria_mib(linha["memoria_request"]),
                )
            )

        tempos = sorted(recomendacoes)

        eixo.plot(
            tempos,
            [recomendacoes[t] for t in tempos],
            linewidth=2.5,
            label="Recomendação VPA",
        )

        for indice, (pod, valores) in enumerate(
            sorted(pods.items()), start=1
        ):
            valores.sort()

            eixo.step(
                [t for t, _ in valores],
                [mem for _, mem in valores],
                where="post",
                label=f"Pod {indice} — memory request",
            )

        eixo.set_title(titulo)
        eixo.set_ylabel("Memória (MiB)")
        eixo.set_xlabel("Tempo desde o início da coleta (s)")
        eixo.grid(alpha=0.25)
        eixo.legend()

    fig.suptitle(
        "Atividade 5.2 — VPA automático: memória aplicada",
        fontsize=15,
        fontweight="bold",
    )

    salvar(fig, "vpa-auto-memoria-aplicada.png")


grafico_off()
grafico_auto()

print("Gráficos de memória concluídos.")
