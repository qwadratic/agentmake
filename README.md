# agentmake

**`make` is the agent orchestrator you already have.** Write a goal, get a dep-ordered swarm of agents building it — parallel, resumable, gated.

## What / why

agentmake turns `make` into an agentic build engine:

- `goal.md` → planning agent decomposes into `plan.json`
- `jq` generates `components.mk` — the DAG comes from the agent, the scheduling from make
- one build agent per component, dep-ordered, parallel with `-j`
- every artifact gated: plan validity, per-component `check.sh`, reviewer `VERDICT: PASS`
- `.DELETE_ON_ERROR` = failed agent never counts as done; rerun `make` resumes exactly where it stopped
- `make progress` census, `make graph` mermaid, visual evals via lowres screenshots (`evals/snap` + `evals/evalshot`)

Your project Makefile is 3 lines:

```make
GOAL ?= goal.md
include engine/build.mk
```

## Quickstart

```
TODO: clone-and-run instructions (see backlog: viral packaging)
```

## Demos

| Demo | Goal | Result |
|------|------|--------|
| _coming soon_ | | |

## Media

_screenshots / gifs / diff-videos coming — see `media/`_
