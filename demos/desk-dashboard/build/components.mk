build/app-shell.done: build/plan.json 
	$(AGENT) build app-shell
	bash src/app-shell/check.sh
	touch $@
COMPONENTS += build/app-shell.done

build/clock-panel.done: build/plan.json build/app-shell.done
	$(AGENT) build clock-panel
	bash src/clock-panel/check.sh
	touch $@
COMPONENTS += build/clock-panel.done

build/weather-panel.done: build/plan.json build/app-shell.done
	$(AGENT) build weather-panel
	bash src/weather-panel/check.sh
	touch $@
COMPONENTS += build/weather-panel.done

build/todo-scratchpad.done: build/plan.json build/app-shell.done
	$(AGENT) build todo-scratchpad
	bash src/todo-scratchpad/check.sh
	touch $@
COMPONENTS += build/todo-scratchpad.done

build/polish-pass.done: build/plan.json build/clock-panel.done build/weather-panel.done build/todo-scratchpad.done
	$(AGENT) build polish-pass
	bash src/polish-pass/check.sh
	touch $@
COMPONENTS += build/polish-pass.done

