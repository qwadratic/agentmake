build/progress-data-collector.done: build/plan.json 
	$(AGENT) build progress-data-collector
	bash src/progress-data-collector/check.sh
	touch $@
COMPONENTS += build/progress-data-collector.done

build/json-schema-def.done: build/plan.json 
	$(AGENT) build json-schema-def
	bash src/json-schema-def/check.sh
	touch $@
COMPONENTS += build/json-schema-def.done

build/json-emitter.done: build/plan.json build/progress-data-collector.done build/json-schema-def.done
	$(AGENT) build json-emitter
	bash src/json-emitter/check.sh
	touch $@
COMPONENTS += build/json-emitter.done

build/make-progress-json-target.done: build/plan.json build/json-emitter.done
	$(AGENT) build make-progress-json-target
	bash src/make-progress-json-target/check.sh
	touch $@
COMPONENTS += build/make-progress-json-target.done

build/parity-check.done: build/plan.json build/make-progress-json-target.done
	$(AGENT) build parity-check
	bash src/parity-check/check.sh
	touch $@
COMPONENTS += build/parity-check.done

