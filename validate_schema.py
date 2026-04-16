#!/usr/bin/env python3
"""
JSON Schema Validation Script
Validates bot_config.json files against the schema
Requires: pip install jsonschema
"""

import sys
import json
from pathlib import Path

try:
    from jsonschema import validate, ValidationError, SchemaError
except ImportError:
    print("❌ jsonschema not installed. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "jsonschema"])
    from jsonschema import validate, ValidationError, SchemaError


def validate_json_schema(json_file: str, schema_file: str) -> bool:
    """
    Validate JSON file against schema
    
    Args:
        json_file: Path to JSON file to validate
        schema_file: Path to JSON schema file
        
    Returns:
        True if valid, False otherwise
    """
    # Colors
    RED = '\033[0;31m'
    GREEN = '\033[0;32m'
    YELLOW = '\033[1;33m'
    NC = '\033[0m'
    
    # Check files exist
    json_path = Path(json_file)
    schema_path = Path(schema_file)
    
    if not json_path.exists():
        print(f"{RED}❌ JSON file not found: {json_file}{NC}")
        return False
    
    if not schema_path.exists():
        print(f"{RED}❌ Schema file not found: {schema_file}{NC}")
        return False
    
    # Load files
    try:
        with open(json_path, 'r') as f:
            json_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"{RED}❌ Invalid JSON in {json_path.name}: {e}{NC}")
        return False
    
    try:
        with open(schema_path, 'r') as f:
            schema_data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"{RED}❌ Invalid JSON in schema file: {e}{NC}")
        return False
    
    # Validate
    print(f"🔍 Validating: {json_path.name}")
    
    try:
        validate(instance=json_data, schema=schema_data)
        print(f"{GREEN}✅ Schema validation passed: {json_path.name}{NC}")
        return True
    except ValidationError as e:
        print(f"{RED}❌ Schema validation failed for: {json_path.name}{NC}")
        print(f"{YELLOW}Error: {e.message}{NC}")
        if e.path:
            print(f"{YELLOW}Path: {' -> '.join(str(p) for p in e.path)}{NC}")
        if e.context:
            print(f"{YELLOW}Context:{NC}")
            for ctx_error in e.context:
                print(f"  - {ctx_error.message}")
        return False
    except SchemaError as e:
        print(f"{RED}❌ Invalid schema file: {e.message}{NC}")
        return False


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("❌ Usage: validate_schema.py <json_file> <schema_file>")
        sys.exit(1)
    
    json_file = sys.argv[1]
    schema_file = sys.argv[2]
    
    if validate_json_schema(json_file, schema_file):
        sys.exit(0)
    else:
        sys.exit(1)