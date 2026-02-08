#!/usr/bin/env python3
"""
Validate CCR package JSON files.
Usage: python validate.py [package_name]
       python validate.py --all
"""

import json
import sys
import os
from pathlib import Path
from typing import Optional
import re

REGISTRY_DIR = Path(__file__).parent.parent / "registry" / "packages"

REQUIRED_FIELDS = ["name", "description", "homepage", "license", "repository", "versions", "default_version", "targets", "maintainers"]
REQUIRED_VERSION_FIELDS = ["git_tag", "tested"]
VALID_REPO_TYPES = ["github", "gitlab", "url"]
NAME_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")

# Common SPDX license identifiers
VALID_LICENSES = {
    "MIT", "Apache-2.0", "BSD-2-Clause", "BSD-3-Clause", "BSL-1.0",
    "MPL-2.0", "LGPL-2.1", "LGPL-3.0", "GPL-2.0", "GPL-3.0",
    "Unlicense", "ISC", "Zlib", "CC0-1.0"
}


class ValidationError(Exception):
    pass


def validate_package(pkg_path: Path) -> list[str]:
    """Validate a single package file. Returns list of errors."""
    errors = []
    
    try:
        with open(pkg_path) as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        return [f"Invalid JSON: {e}"]
    
    # Check required fields
    for field in REQUIRED_FIELDS:
        if field not in data:
            errors.append(f"Missing required field: {field}")
    
    if errors:
        return errors  # Can't continue without required fields
    
    # Validate name
    name = data["name"]
    if not NAME_PATTERN.match(name):
        errors.append(f"Invalid name '{name}': must be lowercase alphanumeric + underscore, starting with letter")
    
    if pkg_path.stem != name:
        errors.append(f"Filename '{pkg_path.stem}' doesn't match package name '{name}'")
    
    # Validate description
    if len(data["description"]) > 200:
        errors.append("Description exceeds 200 characters")
    
    # Validate license
    if data["license"] not in VALID_LICENSES:
        errors.append(f"Unknown license '{data['license']}'. Use SPDX identifier.")
    
    # Validate repository
    repo = data["repository"]
    if "type" not in repo or "url" not in repo:
        errors.append("Repository must have 'type' and 'url' fields")
    elif repo["type"] not in VALID_REPO_TYPES:
        errors.append(f"Invalid repository type: {repo['type']}")
    
    # Validate versions
    versions = data["versions"]
    if not versions:
        errors.append("At least one version is required")
    
    for ver, ver_info in versions.items():
        for field in REQUIRED_VERSION_FIELDS:
            if field not in ver_info:
                errors.append(f"Version {ver} missing required field: {field}")
        
        if "cmake_options" in ver_info:
            if not isinstance(ver_info["cmake_options"], dict):
                errors.append(f"Version {ver}: cmake_options must be an object")
    
    # Validate default_version exists
    if data["default_version"] not in versions:
        errors.append(f"default_version '{data['default_version']}' not found in versions")
    
    # Validate targets
    if not data["targets"]:
        errors.append("At least one target must be specified")
    
    # Validate maintainers
    if not data["maintainers"]:
        errors.append("At least one maintainer is required")
    
    # Validate dependencies
    if "dependencies" in data:
        for dep in data["dependencies"]:
            if "name" not in dep:
                errors.append("Dependency missing 'name' field")
    
    return errors


def validate_all() -> dict[str, list[str]]:
    """Validate all packages. Returns dict of package name -> errors."""
    results = {}
    
    for pkg_file in REGISTRY_DIR.glob("*.json"):
        errors = validate_package(pkg_file)
        if errors:
            results[pkg_file.stem] = errors
    
    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate.py [package_name | --all]")
        sys.exit(1)
    
    if sys.argv[1] == "--all":
        results = validate_all()
        if results:
            print("❌ Validation errors found:\n")
            for pkg, errors in results.items():
                print(f"  {pkg}:")
                for error in errors:
                    print(f"    - {error}")
            sys.exit(1)
        else:
            print("✅ All packages valid!")
            sys.exit(0)
    else:
        pkg_name = sys.argv[1]
        pkg_path = REGISTRY_DIR / f"{pkg_name}.json"
        
        if not pkg_path.exists():
            print(f"❌ Package '{pkg_name}' not found")
            sys.exit(1)
        
        errors = validate_package(pkg_path)
        if errors:
            print(f"❌ Validation errors for {pkg_name}:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)
        else:
            print(f"✅ {pkg_name} is valid!")
            sys.exit(0)


if __name__ == "__main__":
    main()
