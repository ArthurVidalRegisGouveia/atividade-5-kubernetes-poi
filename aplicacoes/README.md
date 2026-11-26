# Código-fonte das três APIs

Os arquivos `main.py` deste diretório são cópias do código-fonte publicado no repositório **[Atividade 2 — POI](https://github.com/ArthurVidalRegisGouveia/atividade-2-poi)**, preservadas aqui para facilitar a apresentação da Atividade 5.1.

| Perfil | Código nesta atividade | Código original | Endpoint |
| --- | --- | --- | --- |
| CPU-bound | [cpu_bound/main.py](cpu_bound/main.py) | [Atividade 2](https://github.com/ArthurVidalRegisGouveia/atividade-2-poi/blob/main/apps/cpu_bound/main.py) | `/primos` |
| Memory-bound | [memory_bound/main.py](memory_bound/main.py) | [Atividade 2](https://github.com/ArthurVidalRegisGouveia/atividade-2-poi/blob/main/apps/memory_bound/main.py) | `/memoria` |
| I/O-bound | [io_bound/main.py](io_bound/main.py) | [Atividade 2](https://github.com/ArthurVidalRegisGouveia/atividade-2-poi/blob/main/apps/io_bound/main.py) | `/arquivo` |

As imagens realmente utilizadas pelos Deployments são `arthuurvidaal/poi-cpu:atividade4`, `arthuurvidaal/poi-memory:atividade4` e `arthuurvidaal/poi-io:atividade4`. **A equivalência exata entre estes arquivos da Atividade 2 e o código embutido em cada imagem Docker Hub não foi auditada.** Esta pasta registra sua origem comprovada, sem alegar que foi feito novo build ou redeploy.

Os três serviços oferecem `GET /health`.
