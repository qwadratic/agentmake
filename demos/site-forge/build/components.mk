build/cli-scaffold.done: build/plan.json 
	$(AGENT) build cli-scaffold
	bash src/cli-scaffold/check.sh
	touch $@
COMPONENTS += build/cli-scaffold.done

build/md-core.done: build/plan.json build/cli-scaffold.done
	$(AGENT) build md-core
	bash src/md-core/check.sh
	touch $@
COMPONENTS += build/md-core.done

build/site-assembly.done: build/plan.json build/md-core.done
	$(AGENT) build site-assembly
	bash src/site-assembly/check.sh
	touch $@
COMPONENTS += build/site-assembly.done

build/plugin-subsystem.done: build/plan.json build/site-assembly.done
	$(ENGINE)subtree plugin-subsystem
	+$(MAKE) -C src/plugin-subsystem GOAL=goal.md B=build SRC=src AGENTMAKE_DEPTH=1 MAXTIER=$$(jq -r .tier build/effort.json) all
	bash src/plugin-subsystem/check.sh
	touch $@
COMPONENTS += build/plugin-subsystem.done

build/themes.done: build/plan.json build/site-assembly.done build/plugin-subsystem.done
	$(AGENT) build themes
	bash src/themes/check.sh
	touch $@
COMPONENTS += build/themes.done

build/self-demo.done: build/plan.json build/md-core.done build/site-assembly.done build/plugin-subsystem.done build/themes.done
	$(AGENT) build self-demo
	bash src/self-demo/check.sh
	touch $@
COMPONENTS += build/self-demo.done

