Implement component '${ID}': ${DESC}

Part of larger goal:
${GOAL_TEXT}

Already-built sibling components (readable for integration): ${SIBLINGS}

Rules:
- write ALL files under ${SRC}/${ID}/
- python3 stdlib + sqlite3 only; no pip, no docker, no network installs
- MUST create executable ${SRC}/${ID}/check.sh: non-interactive self-test, exits 0 on success,
  starts/stops any servers it needs itself, finishes under 60s
- keep it MVP-minimal
