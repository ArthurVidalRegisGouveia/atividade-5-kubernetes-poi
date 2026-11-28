import csv
from datetime import datetime
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt

BASE = Path.home() / "atividade-5.2"
RESULTADOS = BASE / "resultados"
GRAFICOS = BASE / "consolidacao" / "graficos"
GRAFICOS.mkdir(parents=True, exist_ok=True)


def ler(cenario):
    caminho = RESULTADOS / cenario / "metricas.csv"
    with caminho.open(encoding="utf-8", newline="") as arquivo:
        linhas = list(csv.DictReader(arquivo))

    if not linhas:
        raise ValueError(f"CSV vazio: {caminho}")

    inicio = datetime.fromisoformat(
        linhas[0]["data_utc"].replace("Z", "+00:00")
    )

    for linha in linhas:
        instante = datetime.fromisoformat(
            linha["data_utc"].replace("Z", "+00:00")
        )
        linha["_tempo"] = (instante - inicio).total_seconds()

    return linhas


def numero(valor):
    if not valor:
        return float("nan")
    return float(valor)


def millicores(valor):
    if not valor:
        return float("nan")
    if valor.endswith("m"):
        return float(valor[:-1])
    return float(valor) * 1000


def salvar(figura, nome):
    destino = GRAFICOS / nome
    figura.tight_layout()
    figura.savefig(destino, dpi=160, bbox_inches="tight")
    plt.close(figura)
    print(f"Gerado: {destino}")


def grafico_hpa(aplicacao, titulo):
    fig, eixos = plt.subplots(3, 1, figsize=(12, 10))

    for politica in ("50", "75"):
        linhas = ler(f"hpa-{aplicacao}-{politica}")
        tempo = [r["_tempo"] for r in linhas]

        # O CSV de IO registra consumo total;
        # o de Memory usa nomes diferentes.
        if aplicacao == "io":
            coluna_cpu = "cpu_total_millicores"
            coluna_memoria = "memoria_total_mib"
        else:
            coluna_cpu = "cpu_millicores"
            coluna_memoria = "memoria_mib"

        cpu = [numero(r[coluna_cpu]) for r in linhas]
        memoria = [numero(r[coluna_memoria]) for r in linhas]
        replicas = [numero(r["replicas_prontas"]) for r in linhas]

        rotulo = f"HPA {politica}%"

        eixos[0].plot(tempo, cpu, marker=".", label=rotulo)
        eixos[1].plot(tempo, memoria, marker=".", label=rotulo)
        eixos[2].step(
            tempo, replicas, where="post", label=rotulo
        )

    titulos = [
        "CPU observada",
        "Memória observada",
        "Réplicas prontas",
    ]
    unidades = ["CPU (m)", "Memória (MiB)", "Réplicas"]

    for eixo, nome, unidade in zip(eixos, titulos, unidades):
        eixo.set_title(nome)
        eixo.set_ylabel(unidade)
        eixo.set_xlabel("Tempo desde o início da coleta (s)")
        eixo.grid(alpha=0.25)
        eixo.legend()

    eixos[2].set_yticks([1, 2])

    fig.suptitle(
        f"Atividade 5.2 — HPA {titulo}: 50% vs 75%",
        fontsize=15,
        fontweight="bold",
    )
    salvar(fig, f"hpa-{aplicacao}-serie.png")


def grafico_vpa_off():
    configuracoes = [
        ("cpu", "CPU-bound", 500),
        ("memory", "Memory-bound", 100),
        ("io", "IO-bound", 100),
    ]

    fig, eixos = plt.subplots(3, 1, figsize=(12, 10))

    for eixo, (aplicacao, titulo, request_original) in zip(
        eixos, configuracoes
    ):
        linhas = ler(f"vpa-{aplicacao}-off")
        tempo = [r["_tempo"] for r in linhas]

        recomendacao = [
            millicores(r["vpa_cpu_recomendada"])
            for r in linhas
        ]

        eixo.plot(
            tempo, recomendacao,
            marker=".",
            label="CPU recomendada pelo VPA",
        )
        eixo.plot(
            tempo,
            [request_original] * len(tempo),
            linestyle="--",
            label="CPU request original",
        )

        eixo.set_title(titulo)
        eixo.set_ylabel("CPU (m)")
        eixo.set_xlabel("Tempo desde o início da coleta (s)")
        eixo.grid(alpha=0.25)
        eixo.legend()

    fig.suptitle(
        "Atividade 5.2 — VPA Off: recomendação vs request",
        fontsize=15,
        fontweight="bold",
    )
    salvar(fig, "vpa-off-cpu-recomendado.png")


def grafico_vpa_auto():
    configuracoes = [
        ("cpu", "CPU-bound"),
        ("memory", "Memory-bound"),
        ("io", "IO-bound"),
    ]

    fig, eixos = plt.subplots(3, 1, figsize=(12, 11))

    for eixo, (aplicacao, titulo) in zip(
        eixos, configuracoes
    ):
        linhas = ler(f"vpa-{aplicacao}-auto")

        # O CSV do VPA CPU usa vpa_cpu.
        coluna_vpa = (
            "vpa_cpu" if aplicacao == "cpu"
            else "vpa_cpu_recomendada"
        )

        recomendacoes = {}
        pods = {}

        for linha in linhas:
            tempo = linha["_tempo"]
            recomendacoes[tempo] = millicores(
                linha[coluna_vpa]
            )

            pod = linha["pod"]
            pods.setdefault(pod, []).append(
                (tempo, millicores(linha["cpu_request"]))
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
                [cpu for _, cpu in valores],
                where="post",
                label=f"Pod {indice} — CPU request",
            )

        eixo.set_title(titulo)
        eixo.set_ylabel("CPU (m)")
        eixo.set_xlabel("Tempo desde o início da coleta (s)")
        eixo.grid(alpha=0.25)
        eixo.legend(fontsize=9)

    fig.suptitle(
        "Atividade 5.2 — VPA automático: CPU aplicada",
        fontsize=15,
        fontweight="bold",
    )
    salvar(fig, "vpa-auto-cpu-aplicado.png")


grafico_hpa("io", "IO-bound")
grafico_hpa("memory", "Memory-bound")
grafico_vpa_off()
grafico_vpa_auto()

print("Todos os gráficos temporais foram gerados.")
