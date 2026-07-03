# agentmake engine — goal.md → plan → components (parallel, dep-ordered) → review gate
#
# Project Makefile is 3 lines:
#   GOAL ?= goal.md        # optional overrides: GOAL, B, SRC, AGENT
#   include engine/build.mk
#
SHELL := /bin/bash
.DELETE_ON_ERROR:  # failed agent ≠ done artifact

ENGINE := $(dir $(lastword $(MAKEFILE_LIST)))
GOAL  ?= goal.md
B     ?= build
SRC   ?= src
AGENT ?= $(ENGINE)agent
export GOAL B SRC   # agent adapter reads these

.PHONY: all progress graph clean

all: $(B)/report.md

# ── Phase 1: decomposition (agent, no tools)
$(B)/plan.json: $(GOAL) | $(B)
	$(AGENT) plan $< > $@
	jq -e '.components | length > 0' $@ > /dev/null   # gate: valid decomposition

# ── Phase 2: plan generates the DAG — dep edges come from the agent
-include $(B)/components.mk
$(B)/components.mk: $(B)/plan.json
	jq -r '.components[] | "$(B)/\(.id).done: $(B)/plan.json \(.deps | map("$(B)/\(.).done") | join(" "))\n\t$$(AGENT) build \(.id)\n\tbash $(SRC)/\(.id)/check.sh\n\ttouch $$@\nCOMPONENTS += $(B)/\(.id).done\n"' $< > $@

# ── Phase 3: reviewer agent gate
$(B)/report.md: $(COMPONENTS)
	$(AGENT) review > $@
	grep -q 'VERDICT: PASS' $@

$(B):
	mkdir -p $@

# ── Observability
ARTIFACTS = $(B)/plan.json $(COMPONENTS) $(B)/report.md
progress:
	@done=0; total=0; \
	for f in $(ARTIFACTS); do \
	  total=$$((total+1)); \
	  if [ -f $$f ]; then done=$$((done+1)); printf ' \033[32m✓\033[0m %s\n' $$f; \
	  else printf ' \033[2m·\033[0m %s\n' $$f; fi; \
	done; \
	pct=$$((done*100/total)); n=$$((done*24/total)); \
	bar=""; [ $$n -gt 0 ] && bar=$$(printf '#%.0s' $$(seq 1 $$n)); \
	printf '[%-24s] %d/%d (%d%%)\n' "$$bar" $$done $$total $$pct

# ponytail: awk-parsed mermaid; ceiling = pattern/order-only deps; upgrade = makefile2graph
graph:
	@echo 'graph TD'; \
	awk -F: '/^[a-zA-Z$$(][^=]*:([^=]|$$)/ && $$1!~/PHONY|DELETE_ON_ERROR/ \
	  {t=$$1; n=split($$2,d," "); for(i=1;i<=n;i++) if(d[i]!="|") printf "  %s --> %s\n", d[i], t}' \
	  $(ENGINE)build.mk $(B)/components.mk 2>/dev/null | sed -e 's/$$(B)/$(B)/g' -e 's/$$(GOAL)/$(GOAL)/g'

clean:
	rm -rf $(B) $(SRC)
