Decompose this goal into 3-5 buildable components.

GOAL:
${GOAL_TEXT}

Output ONLY raw JSON, no markdown fences, schema:
{"components":[{"id":"kebab-case","desc":"what to build, concrete","deps":["ids of components this needs"]}]}
Rules: deps may only reference other listed ids; python3 stdlib + sqlite3 only; each component independently checkable.
