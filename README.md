# KofSentinela — monitor do homelab em Kof

Poller one-shot (sem daemon próprio) + dashboard HTTP + alertas por regra
"3 falhas seguidas". Um `run.sh` amarra tudo; o loop contínuo é bash +
`sleep` (sem depender de `sleep()` nativo).

## Layout

```
kofsentinela/
  run.sh                 once | poll | serve | all | ui-build
  history.jsonl          (gerado) uma rodada por linha
  app/Poller.kf          sondas http|ping|docker + parsing
  app/Store.kf           espelho SQLite opcional (SENTINELA_DB)
  app/Status.kf          rotas kof.web (startStatus)
  app/Main.kf            despacho SENTINELA_MODE + alertas
  app/tests/             kof test (4 testes)
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
./run.sh ui-build # rebuild do bundle KofJS (após editar ui/Dashboard.kf)
```

Modos (`SENTINELA_MODE`): `once` (cron/native), `serve`, `all`.
`all` é um processo só — verificado ao vivo (HTTP + rounds + ALERT).
No native use `once` (sem event loop no target).
Auth: `SENTINELA_API_KEY` (header `x-api-key` ou `?key=`).
SQLite: `SENTINELA_DB=path.db` (tabela `checks`).

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

- `kof check` aceita diretório: `kof check .` dentro de `poller/` ou `status/`.
- Alertas sem state file: janela das últimas 4 rodadas do próprio
  `history.jsonl` (3ª falha seguida = ALERT; janela limpa após falha = RECOVERED).
- Testes: `cd poller && kof test tests/sentinela_test.kof` (3 testes).
- **Native funciona**: `kof run Main.kf --target native` executa sonda
  ping de verdade (binário real, sem JVM) — coletor edge validado.
- Dashboard `/ui`: `Table` dinâmica via `setRows` (N alvos) + botão
  "Atualizar agora" (`on("click")`); só formas 0.6.4-safe.
