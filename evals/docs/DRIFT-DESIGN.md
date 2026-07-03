# DRIFT-DESIGN — drift monitor for parallel junior sessions + single HITL switch

Status: design only, nothing here is built.
Scope: screenshot-based smoke evals over agent-built projects (e.g. `makefile-lab/twitter/`).
Constraints inherited from lab: make-native, python3 stdlib + sqlite3, no pip/docker,
`.DELETE_ON_ERROR`, artifact-gated phases, agent adapter script (`./agent <role> ...`).

---

## Part 1 — Drift monitor

### 1.1 Problem

N junior agent sessions run in parallel against one built project. Each session:
takes screenshots, navigates pages, emits *findings* (visual/functional problems),
proposes/applies fixes. Failure modes supervisor must catch:

| drift mode | symptom |
|---|---|
| hallucinated finding | claim not supported by any screenshot or code |
| stale evidence | cites shot taken before the code it critiques changed |
| mode collapse | sessions converge on identical findings, coverage shrinks |
| fix-loop | same file churned repeatedly, finding never resolves |
| scope escape | session edits components outside its assignment |
| dead session | plausible-looking output, zero grounded signal |

### 1.2 Artifact layout

```
evals/
  sessions/<sid>/
    manifest.json          # persona, focus set, canary set, started-at
    shots/<page>-<ts>.png  # every screenshot the session takes
    findings.jsonl         # append-only, one finding per line
  supervisor/
    grounding.jsonl        # per-finding G-check results
    clusters.json          # cross-session clusters
    verdicts.json          # per-session drift verdict
    verdict.md             # human-readable summary (gated, see Part 2)
```

### 1.3 Finding schema (the contract)

Every finding MUST be one JSON line:

```json
{"fid":"s3-007","session":"s3","page":"/timeline/1",
 "kind":"layout|content|error|a11y|perf",
 "severity":"low|med|high",
 "claim":"timeline shows tweets oldest-first, spec says newest-first",
 "evidence":{
   "shot":"sessions/s3/shots/timeline-1-1735900000.png",
   "region":[120,340,600,200],
   "code":["src/http-api/server.py:142"]},
 "fix":{"files":["src/http-api/server.py"],"summary":"ORDER BY created_at DESC"},
 "status":"open|fixed|verified"}
```

Hard rule: **no evidence, no finding.** `evidence.shot` and `evidence.code` are
mandatory. Junior prompt states this; supervisor enforces it mechanically (below).
Findings failing schema are dropped at ingest, counted against the session.

### 1.4 Evidence-grounding checks

Two tiers. Tier A is mechanical, cheap, runs on every finding. Tier B is an
agent verifier, sampled.

**Tier A (stdlib python, no vision):**

- **G1 shot-exists**: `evidence.shot` is a real file inside *that session's own*
  `shots/` dir (no borrowing other sessions' evidence), mtime inside session window.
- **G2 code-exists**: cited `file:line` exists; line ≤ file length.
- **G3 region-sane**: `region` bbox fits inside PNG dimensions (read w/h from
  IHDR bytes — stdlib, no PIL).
- **G4 freshness**: shot mtime ≥ mtime of every cited code file at capture time.
  A finding whose shot predates the code it critiques = stale evidence.
  Corollary: `status:"verified"` requires a *second* shot taken after the fix.

**Tier B (verifier agent, vision-capable):**

Input: the shot (cropped to region), the claim, ±20 lines around cited code.
Output: single token `GROUNDED` / `UNGROUNDED` + one-line reason.
Sampling budget: 100% of `high` severity, 100% from sessions with any prior
Tier-A/B failure, random 20% of the rest. Verifier never sees which session
produced the finding (blind check).

Per-session `ungrounded_rate` = (A-fail + B-UNGROUNDED) / findings.

### 1.5 Cross-session agreement + outlier clustering

**Comparability first.** Variation (1.6) makes sessions *deliberately* disagree,
so raw agreement is meaningless. Two sessions are comparable on page `p` only if
`p` is in both assignments (or both canary sets). Agreement is computed on the
overlap scope only; persona-unique findings are expected and *not* penalized.

**Clustering (ponytail: stdlib, no embeddings; upgrade path = embedding service):**

1. Exact key: `(normalized_page, kind, primary_code_file)` → same cluster.
2. Fuzzy merge: within same page+kind, `difflib.SequenceMatcher` on claim text
   ≥ 0.6 → merge clusters.

**Per-session metrics:**

| metric | definition | drift signal when |
|---|---|---|
| `overlap_agreement` | overlap-scope findings corroborated by ≥1 other session / overlap-scope findings | low AND ungrounded_rate high |
| `canary_recall` | planted/known defects in scope that session found | low → dead session |
| `ungrounded_rate` | 1.4 | > 0.2 |
| `novelty` | persona-scope singleton findings | fine alone; only suspicious with high ungrounded_rate |
| `fix_churn` | edits touching same file per finding before `fixed` | > 3 → fix-loop |
| `scope_escape` | files edited outside assigned components (from `git diff --name-only` per session branch) | any |
| `pairwise_similarity` | fraction of finding pairs with claim similarity ≥ 0.9 vs another session | > 0.5 → collapse alarm (variation failed) |

Outlier ≠ bad: a singleton finding that *passes grounding* is the whole point of
variation. Outlier + ungrounded = drift. The 2×2:

```
                 grounded        ungrounded
corroborated     high-confidence re-verify (shared hallucination possible
                 fix queue        but rare — Tier B on all members)
singleton        novelty (good)  drift suspect → escalation ladder
```

**Canary calibration (ground truth):** every session's scope includes a small
shared canary set. ponytail v1: canary = checklist of *known real quirks* of the
built app (curated once by supervisor from a manual pass). Upgrade path: mutation
injection — supervisor clones the app, plants k visual defects (drop a CSS rule,
flip timeline sort), runs calibration round, measures recall/precision per
session against known answers. Sessions are never told which pages are canaries.

**Escalation ladder (supervisor actions, in order):**

1. **NOTE** — metric out of band once; log only.
2. **VERIFY** — force Tier-B on 100% of that session's findings.
3. **QUARANTINE** — session's open findings held out of the fix queue; its
   applied fixes reverted (each session works on own git branch; quarantine =
   branch not merged).
4. **RESTART** — kill session, respawn with corrective note in prompt
   ("previous instance produced ungrounded findings about X; every claim must
   cite a fresh screenshot").

### 1.6 Variation strategy (anti-collapse)

Two orthogonal axes, assigned by supervisor in `manifest.json`:

- **Persona** (what to be paranoid about):
  `pixel-perfectionist | error-hunter | a11y-auditor | data-integrity | perf-skeptic`
- **Focus** (where): partition of pages/components.

Assignment matrix rules:
- every page covered by ≥ 2 sessions with *different* personas (enables agreement),
- every session gets the shared canary set (enables calibration),
- no two sessions share both persona and focus (enables novelty).

Prompt-level de-correlation: distinct navigation order, distinct opening task
("start from the emptiest page" vs "start from the busiest"), persona-specific
severity rubric. Do NOT rely on temperature — vary instructions, they're the
reproducible knob.

Collapse detector = `pairwise_similarity` metric above. Alarm ⇒ supervisor
reshuffles personas/focus for next round; that is the feedback loop that keeps
the axes honest.

### 1.7 Make wiring (sketch, mirrors twitter lab pattern)

```make
SIDS := s1 s2 s3 s4
SESSIONS := $(SIDS:%=$(B)/eval/%.findings)

$(B)/eval/%.findings: $(B)/report.md            # only eval a built system
	$(AGENT) junior $* > $@                      # runs session, writes artifacts

$(B)/eval/grounding.ok: $(SESSIONS)
	python3 evals/bin/ground.py evals/sessions > evals/supervisor/grounding.jsonl
	touch $@

$(B)/eval/verdict.md: $(B)/eval/grounding.ok
	python3 evals/bin/cluster.py > evals/supervisor/clusters.json
	$(AGENT) supervise > $@                      # writes verdicts.json + verdict.md
```

Sessions parallelize under `make -j` for free; grounding/clustering is the
fan-in gate, same shape as the component→review gate in `twitter/Makefile`.

---

## Part 2 — Single human-in-the-loop switch

### 2.1 Requirement

One mechanism flips any step — or the whole project — between auto-approval and
human approval. Must be make-native: survives restarts, composes with `-j`,
leaves an audit trail.

### 2.2 Alternatives considered

| option | verdict | why |
|---|---|---|
| interactive `read` in recipe | ✗ | blocks `-j`, no record, dies in CI, re-asks on rerun |
| `ifeq` per recipe | ✗ | scattered N times, parse-time only (can't see `%`), no artifact |
| `.WAIT` / phony pause targets | ✗ | no persistence — approval forgotten across invocations |
| external CI approval / PR review | ✗ | not make-native; second source of truth outside the DAG |
| **gate artifact** `build/approvals/<step>.ok` | ✓ | approval = file. Existence is state, mtime is invalidation, content is audit trail. One pattern rule covers every step. |

### 2.3 Chosen: gate artifact pattern — exact spec

**State model.** Step `X` produces `$(B)/X.done` (built + self-checked, as
today). Downstream consumers depend on `$(B)/approvals/X.ok` *instead of*
`X.done`. The `.ok` depends on the `.done` — you approve a built thing, and a
rebuild (`X.done` newer than `X.ok`) automatically re-opens the gate. Correct
staleness semantics for free from make.

**Knobs (all at invocation, no Makefile edits):**

```
AUTOPILOT=1            # whole project auto  (default 0 = whole project human)
HUMAN_STEPS="http-api" # force human on listed steps even under AUTOPILOT=1
AUTO_STEPS="db-layer"  # force auto on listed steps even under AUTOPILOT=0
```

Precedence per step: `HUMAN_STEPS` > `AUTO_STEPS` > `AUTOPILOT`. That is the
*single switch*: one boolean with two per-step override lists, all funneling
into one pattern rule.

**The Makefile block (drop-in):**

```make
APPROVALS := $(B)/approvals
AUTOPILOT ?= 0
HUMAN_STEPS ?=
AUTO_STEPS ?=

.PRECIOUS: $(APPROVALS)/%.ok

$(APPROVALS)/%.ok: $(B)/%.done | $(APPROVALS)
	@mode=$(if $(filter 1,$(AUTOPILOT)),auto,human); \
	case " $(AUTO_STEPS) "  in *" $* "*) mode=auto;;  esac; \
	case " $(HUMAN_STEPS) " in *" $* "*) mode=human;; esac; \
	if [ $$mode = auto ]; then \
	  $(AGENT) approve $* > $(APPROVALS)/$*.review; \
	  grep -q '^APPROVE' $(APPROVALS)/$*.review; \
	  { echo "approved-by: auto"; date -u +%FT%TZ; \
	    shasum -a 256 $(B)/$*.done; } > $@; \
	else \
	  echo ""; \
	  echo "── HUMAN GATE ────────────────────────────────────"; \
	  echo "  review: src/$*/  and  $(B)/$*.done"; \
	  echo "  then:   make approve-$*"; \
	  echo "──────────────────────────────────────────────────"; \
	  exit 1; \
	fi

approve-%: | $(APPROVALS)
	@test -f $(B)/$*.done || { echo "nothing to approve: $(B)/$*.done missing"; exit 1; }
	@{ echo "approved-by: $$USER"; date -u +%FT%TZ; \
	   shasum -a 256 $(B)/$*.done; } > $(APPROVALS)/$*.ok
	@echo "approved: $*"

unapprove-%:
	rm -f $(APPROVALS)/$*.ok

pending:
	@for f in $(B)/*.done; do s=$$(basename $$f .done); \
	  [ -f $(APPROVALS)/$$s.ok ] || echo "pending: make approve-$$s"; done

$(APPROVALS):
	mkdir -p $@
```

**Wiring into the generated DAG.** One-line change in the `components.mk`
generator jq template: downstream dep edges reference
`$(B)/approvals/\(.).ok` instead of `$(B)/\(.).done`, and the final review
target depends on the `.ok` set. Nothing else changes. Same gate pattern
applies unchanged to eval steps (`approvals/eval-verdict.ok` gates acting on
supervisor verdicts) and to the review step itself.

**Semantics worth stating:**

- *Auto path* is itself a gate, not a rubber stamp: `$(AGENT) approve <step>`
  is an approver agent that inspects the artifact and must print a line
  starting `APPROVE`; anything else fails the recipe, `.DELETE_ON_ERROR`
  removes the half-written `.ok`, build stops. Its reasoning is kept in
  `<step>.review` for audit.
- *Human path* fails the target with printed instructions. Run `make -k` so
  one blocked gate doesn't stall parallel siblings — every reachable step
  builds, every human gate prints its instruction, `make pending` lists the
  queue. Approvals persist as files; rerunning `make` resumes exactly where
  the human left off.
- *Audit*: each `.ok` records who, when, and the sha256 of the artifact that
  was actually reviewed. If content changes later, mtime chain re-opens the
  gate; the sha proves what the recorded approval applied to.
- *Revoke*: `make unapprove-X` reopens one gate; `rm -rf build/approvals`
  reopens all. `.PRECIOUS` keeps `.ok` files safe from make's intermediate
  cleanup.

### 2.4 Interaction of the two designs

The HITL switch is how drift-monitor verdicts become actions: supervisor's
`verdict.md` is just another step artifact behind `approvals/eval-verdict.ok`.
`AUTOPILOT=1` → auto-approver applies the ladder (quarantine/restart)
autonomously; default → human reads `verdict.md`, then `make approve-eval-verdict`.
One mechanism, both worlds.
