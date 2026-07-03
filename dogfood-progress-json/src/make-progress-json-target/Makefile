# progress-json: machine-readable progress census on stdout, nothing else.
# BUILD_DIR overridable for tests/fixtures.
BUILD_DIR ?= $(CURDIR)/../../build

.PHONY: progress-json
progress-json:
	@python3 $(CURDIR)/../json-emitter/emit.py $(BUILD_DIR)
