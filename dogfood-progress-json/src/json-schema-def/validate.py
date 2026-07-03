#!/usr/bin/env python3
"""Minimal JSON Schema validator (stdlib only).

ponytail: covers only the keywords progress.schema.json uses
(type, required, properties, additionalProperties, items, minimum,
maximum, pattern). Upgrade path: pip install jsonschema.

Usage: validate.py schema.json instance.json
"""
import json, re, sys

TYPES = {
    "object": dict, "array": list, "string": str,
    "integer": int, "number": (int, float), "boolean": bool,
}

def check(schema, data, path="$"):
    t = schema.get("type")
    if t:
        py = TYPES[t]
        if not isinstance(data, py) or (t in ("integer", "number") and isinstance(data, bool)):
            fail(f"{path}: expected {t}, got {type(data).__name__}")
    for k in schema.get("required", []):
        if k not in data:
            fail(f"{path}: missing required key '{k}'")
    props = schema.get("properties", {})
    if isinstance(data, dict):
        if schema.get("additionalProperties") is False:
            extra = set(data) - set(props)
            if extra:
                fail(f"{path}: unexpected keys {sorted(extra)}")
        for k, sub in props.items():
            if k in data:
                check(sub, data[k], f"{path}.{k}")
    if isinstance(data, list) and "items" in schema:
        for i, item in enumerate(data):
            check(schema["items"], item, f"{path}[{i}]")
    if "minimum" in schema and isinstance(data, (int, float)) and data < schema["minimum"]:
        fail(f"{path}: {data} < minimum {schema['minimum']}")
    if "maximum" in schema and isinstance(data, (int, float)) and data > schema["maximum"]:
        fail(f"{path}: {data} > maximum {schema['maximum']}")
    if "pattern" in schema and isinstance(data, str) and not re.search(schema["pattern"], data):
        fail(f"{path}: '{data}' does not match pattern {schema['pattern']}")

def fail(msg):
    print(f"INVALID: {msg}", file=sys.stderr)
    sys.exit(1)

if __name__ == "__main__":
    schema = json.load(open(sys.argv[1]))
    data = json.load(open(sys.argv[2]))
    check(schema, data)
    print("valid")
