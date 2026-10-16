# KofSentinela — monitor do homelab em Kof

Poller one-shot (sem daemon próprio) + dashboard HTTP + alertas por regra
"3 falhas seguidas". Um `run.sh` amarra tudo; o loop contínuo é bash +
`sleep` (sem depender de `sleep()` nativo).

## Layout

```
kofsentinela/
  run.sh                 poll | once | status | ui-build
  history.jsonl          (gerado) uma rodada por linha
  poller/Poller.kf       sondas http|ping|docker + alertas
  poller/Main.kf         uma rodada: sonda, append, avalia
  status/Main.kf         daemon kof.web: / (HTML) + /api/status + /api/board + /ui/*
  ui/Dashboard.kf        dashboard vivo KofJS (poll 10s, 8 slots)
  ui/ui-dist/            (gerado) bundle JS — commitar? não; rebuild via ui-build
```

## Uso

```bash
cd /home/thiago/Documents/Work-Projects/kofsentinela
export SENTINELA_TARGETS="kofbox;http;http://localhost:8099/api/health,roteador;ping;192.168.1.1,pg;docker;kofbox-postgres"
./run.sh once     # uma rodada
./run.sh poll     # loop (INTERVAL=30)
./run.sh status   # dashboard em http://localhost:8090 (STATUS_PORT muda)
./run.sh ui-build # rebuild do bundle KofJS (após editar ui/Dashboard.kf)
```

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
