# make-target: `next-goal` wires board-reader -> next-task-selector -> goal-md-generator.
# Vars: BOARD=path/to/board.md (default: auto-discover under ROOT), ROOT=. , OUT=goal.md, FORCE=1 to overwrite.
MK_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
SRC := $(MK_DIR)..

ROOT ?= .
OUT ?= goal.md
ifdef BOARD
READER_ARGS := $(BOARD)
else
READER_ARGS := --root $(ROOT)
endif

.PHONY: next-goal
next-goal:
	@if [ -e "$(OUT)" ] && [ "$(FORCE)" != "1" ]; then \
		echo "next-goal: $(OUT) already exists; rerun with FORCE=1 to overwrite" >&2; exit 1; \
	fi
	@node "$(SRC)/board-reader/board-reader.js" $(READER_ARGS) \
		| node "$(SRC)/next-task-selector/next-task-selector.js" \
		| node "$(SRC)/goal-md-generator/goal-md-generator.js" "$(OUT)"
	@echo "next-goal: wrote $(OUT)"
