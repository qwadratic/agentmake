build/life-engine.done: build/plan.json 
	$(AGENT) build life-engine
	bash src/life-engine/check.sh
	touch $@
COMPONENTS += build/life-engine.done

build/canvas-renderer.done: build/plan.json build/life-engine.done
	$(AGENT) build canvas-renderer
	bash src/canvas-renderer/check.sh
	touch $@
COMPONENTS += build/canvas-renderer.done

build/animation-app.done: build/plan.json build/life-engine.done build/canvas-renderer.done
	$(AGENT) build animation-app
	bash src/animation-app/check.sh
	touch $@
COMPONENTS += build/animation-app.done

