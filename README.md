# KofSentinela — monitor do homelab em Kof

Poller one-shot (sem daemon próprio) + dashboard HTTP + alertas por regra
"3 falhas seguidas". Um `run.sh` amarra tudo; o loop contínuo é bash +
`sleep` (sem depender de `sleep()` nativo).

## Layout

```
kofsentinela/
  run.sh                 once | poll | serve | all | once-native | poll-native | ui-build
  history.jsonl          (gerado) uma rodada por linha
  app/Poller.kf          sondas http|ping|docker + parsing
  app/Store.kf           espelho SQLite (SENTINELA_DB) + p50/p99 (latencyStats)
  app/Status.kf          rotas kof.web (startStatus) + /api/latency
  app/Main.kf            despacho SENTINELA_MODE + alertas
  app/tests/             kof test (4 testes)
  native/Main.kf         coletor edge auto-contido (sem kof.web) p/ --target native
  ui/Dashboard.kf        dashboard vivo KofJS (poll 10s, tabela dinâmica)
  ui/ui-dist/            (gerado, gitignored) bundle JS
```

## Uso

```bash
cd /home/thiago/Documents/Work-Projects/kofsentinela
export SENTINELA_TARGETS="kofbox;http;http://localhost:8099/api/health,roteador;ping;192.168.1.1,pg;docker;kofbox-postgres"
./run.sh once     # uma rodada
./run.sh poll     # loop bash (INTERVAL=30)
./run.sh serve    # só HTTP (precisa poller externo)
./run.sh all      # HTTP + polling interno (scheduler.every; JVM)
./run.sh once-native  # uma rodada com coletor edge (binário native, sem JVM)
./run.sh poll-native  # loop bash do coletor native (Pi)
./run.sh ui-build # rebuild do bundle KofJS (após editar ui/Dashboard.kf)
```

Modos (`SENTINELA_MODE`): `once` (cron/native), `serve`, `all`.
`all` é um processo só — verificado ao vivo (HTTP + rounds + ALERT).
Auth: `SENTINELA_API_KEY` (header `x-api-key` ou `?key=`).
SQLite: `SENTINELA_DB=path.db` (tabela `checks`).
Latência: `GET /api/latency` → `nome;p50;p99;n` por alvo (das últimas 100
rodadas `up=1` do `checks`; sem db → `;-;0`).

**Coletor native** (`native/Main.kf`): `app/` é um pacote único e o
`Status.kf` usa `kof.web` (header/headerSet/query), que o driver native
não tem (WEB001). Por isso o coletor edge é um pacote próprio, auto-contido
(poller + store + alerta, sem web), que compila em `--target native`.
Verificado: `cd native && kof run Main.kf --target native` grava rodada
real (ping de verdade) em `history.jsonl`.

Dashboard vivo em `/ui`: `ui/Dashboard.kf` (KofJS puro — `scheduler.every`
+ `http.get("/api/board")` mesma origem + `setText`, 8 slots) servido pelo
daemon de status. Só formas 0.6.4-safe (Window/Label 1-arg, bind, show,
setText — ver doc da varredura). Limite honesto: sem browser aqui, pixels
não verificados — abrir `http://localhost:8090/ui` e conferir os 8 slots.

## Env

| Var | Default | Uso |
|---|---|---|
| `SENTINELA_TARGETS` | example+localhost | `nome;kind;alvo,...` |
| `SENTINELA_HISTORY` | `../history.jsonl` | JSONL das rodadas |
| `STATUS_PORT` | `8090` | porta do dashboard |
| `INTERVAL` | `30` | segundos entre rodadas (run.sh) |

## Notas

- `kof check` aceita diretório: `kof check .` dentro de `app/` ou `native/`.
- Alertas sem state file: janela das últimas 4 rodadas do próprio
  `history.jsonl` (3ª falha seguida = ALERT; janela limpa após falha = RECOVERED).
- Testes: `cd app && kof test tests/sentinela_test.kof` (4 testes).
- **Native funciona**: `./run.sh once-native` executa sonda ping de verdade
  (binário real, sem JVM) — coletor edge validado.
- Dashboard `/ui`: `Table` dinâmica via `setRows` (N alvos) + botão
  "Atualizar agora" (`on("click")`); só formas 0.6.4-safe.
