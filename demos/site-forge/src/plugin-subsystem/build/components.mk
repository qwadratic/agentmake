build/plugin-loader.done: build/plan.json 
	$(AGENT) build plugin-loader
	bash src/plugin-loader/check.sh
	touch $@
COMPONENTS += build/plugin-loader.done

build/hook-contract-docs.done: build/plan.json build/plugin-loader.done
	$(AGENT) build hook-contract-docs
	bash src/hook-contract-docs/check.sh
	touch $@
COMPONENTS += build/hook-contract-docs.done

build/highlight-plugin.done: build/plan.json build/plugin-loader.done
	$(AGENT) build highlight-plugin
	bash src/highlight-plugin/check.sh
	touch $@
COMPONENTS += build/highlight-plugin.done

build/rss-plugin.done: build/plan.json build/plugin-loader.done
	$(AGENT) build rss-plugin
	bash src/rss-plugin/check.sh
	touch $@
COMPONENTS += build/rss-plugin.done

build/subsystem-integration.done: build/plan.json build/plugin-loader.done build/highlight-plugin.done build/rss-plugin.done build/hook-contract-docs.done
	$(AGENT) build subsystem-integration
	bash src/subsystem-integration/check.sh
	touch $@
COMPONENTS += build/subsystem-integration.done

