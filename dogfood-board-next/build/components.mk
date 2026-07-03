build/board-reader.done: build/plan.json 
	$(AGENT) build board-reader
	bash src/board-reader/check.sh
	touch $@
COMPONENTS += build/board-reader.done

build/next-task-selector.done: build/plan.json build/board-reader.done
	$(AGENT) build next-task-selector
	bash src/next-task-selector/check.sh
	touch $@
COMPONENTS += build/next-task-selector.done

build/goal-md-generator.done: build/plan.json build/next-task-selector.done
	$(AGENT) build goal-md-generator
	bash src/goal-md-generator/check.sh
	touch $@
COMPONENTS += build/goal-md-generator.done

build/make-target.done: build/plan.json build/board-reader.done build/next-task-selector.done build/goal-md-generator.done
	$(AGENT) build make-target
	bash src/make-target/check.sh
	touch $@
COMPONENTS += build/make-target.done

