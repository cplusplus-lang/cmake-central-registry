#!/usr/bin/env python3
"""
Validate CCR package registry using BCR-style folder structure.
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

# Required fields for metadata.json
REQUIRED_METADATA_FIELDS = ["name", "description", "homepage", "license", "repository", "default_version", "targets", "maintainers"]

# Required fields for source.json
REQUIRED_SOURCE_FIELDS = ["git_tag", "tested"]

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


def validate_metadata(pkg_dir: Path, metadata: dict) -> list[str]:
    """Validate metadata.json content."""
    errors = []
    
    # Check required fields
    for field in REQUIRED_METADATA_FIELDS:
        if field not in metadata:
            errors.append(f"metadata.json missing required field: {field}")
    
    if errors:
        return errors  # Can't continue without required fields
    
    # Validate name matches directory
    name = metadata["name"]
    if not NAME_PATTERN.match(name):
        errors.append(f"Invalid name '{name}': must be lowercase alphanumeric + underscore, starting with letter")
    
    if pkg_dir.name != name:
        errors.append(f"Directory name '{pkg_dir.name}' doesn't match package name '{name}'")
    
    # Validate description
    if len(metadata["description"]) > 200:
        errors.append("Description exceeds 200 characters")
    
    # Validate license
    if metadata["license"] not in VALID_LICENSES:
        errors.append(f"Unknown license '{metadata['license']}'. Use SPDX identifier.")
    
    # Validate repository
    repo = metadata["repository"]
    if "type" not in repo or "url" not in repo:
        errors.append("Repository must have 'type' and 'url' fields")
    elif repo["type"] not in VALID_REPO_TYPES:
        errors.append(f"Invalid repository type: {repo['type']}")
    
    # Validate targets
    if not metadata["targets"]:
        errors.append("At least one target must be specified")
    
    # Validate maintainers
    if not metadata["maintainers"]:
        errors.append("At least one maintainer is required")
    
    # Validate dependencies if present
    if "dependencies" in metadata:
        for dep in metadata["dependencies"]:
            if "name" not in dep:
                errors.append("Dependency missing 'name' field")
    
    return errors


def validate_source(version: str, source: dict) -> list[str]:
    """Validate source.json content."""
    errors = []
    
    for field in REQUIRED_SOURCE_FIELDS:
        if field not in source:
            errors.append(f"Version {version}: source.json missing required field: {field}")
    
    if "cmake_options" in source:
        if not isinstance(source["cmake_options"], dict):
            errors.append(f"Version {version}: cmake_options must be an object")
    
    return errors


def get_version_dirs(pkg_dir: Path) -> list[Path]:
    """Get all version directories in a package directory."""
    return [d for d in pkg_dir.iterdir() if d.is_dir()]


def validate_package(pkg_dir: Path) -> list[str]:
    """Validate a single package directory. Returns list of errors."""
    errors = []
    
    # Check metadata.json exists
    metadata_path = pkg_dir / "metadata.json"
    if not metadata_path.exists():
        return [f"Missing metadata.json in {pkg_dir.name}"]
    
    try:
        with open(metadata_path) as f:
            metadata = json.load(f)
    except json.JSONDecodeError as e:
        return [f"Invalid JSON in metadata.json: {e}"]
    
    # Validate metadata
    errors.extend(validate_metadata(pkg_dir, metadata))
    
    # Get version directories
    version_dirs = get_version_dirs(pkg_dir)
    if not version_dirs:
        errors.append("At least one version directory is required")
        return errors
    
    versions_found = []
    for ver_dir in version_dirs:
        version = ver_dir.name
        versions_found.append(version)
        
        source_path = ver_dir / "source.json"
        if not source_path.exists():
            errors.append(f"Version {version}: missing source.json")
            continue
        
        try:
            with open(source_path) as f:
                source = json.load(f)
        except json.JSONDecodeError as e:
            errors.append(f"Version {version}: invalid JSON in source.json: {e}")
            continue
        
        errors.extend(validate_source(version, source))
    
    # Validate default_version exists
    if "default_version" in metadata:
        if metadata["default_version"] not in versions_found:
            errors.append(f"default_version '{metadata['default_version']}' not found in version directories")
    
    return errors


def validate_all() -> dict[str, list[str]]:
    """Validate all packages. Returns dict of package name -> errors."""
    results = {}
    
    if not REGISTRY_DIR.exists():
        print(f"❌ Registry directory not found: {REGISTRY_DIR}")
        sys.exit(1)
    
    for pkg_dir in REGISTRY_DIR.iterdir():
        if pkg_dir.is_dir():
            errors = validate_package(pkg_dir)
            if errors:
                results[pkg_dir.name] = errors
    
    return results


def main():
    if len(sys.argv) < 2:
        print("Usage: python validate.py [package_name | --all]")
        sys.exit(1)
    
    if sys.argv[1] == "--all":
        results = validate_all()
        
        # Count packages
        pkg_count = sum(1 for p in REGISTRY_DIR.iterdir() if p.is_dir())
        
        if results:
            print("❌ Validation errors found:\n")
            for pkg, errors in sorted(results.items()):
                print(f"  {pkg}:")
                for error in errors:
                    print(f"    - {error}")
            print(f"\n{pkg_count - len(results)}/{pkg_count} packages valid")
            sys.exit(1)
        else:
            print(f"✅ All {pkg_count} packages valid!")
            sys.exit(0)
    else:
        pkg_name = sys.argv[1]
        pkg_dir = REGISTRY_DIR / pkg_name
        
        if not pkg_dir.exists():
            print(f"❌ Package '{pkg_name}' not found")
            sys.exit(1)
        
        errors = validate_package(pkg_dir)
        if errors:
            print(f"❌ Validation errors for {pkg_name}:")
            for error in errors:
                print(f"  - {error}")
            sys.exit(1)
        else:
            # Count versions
            version_count = len(get_version_dirs(pkg_dir))
            print(f"✅ {pkg_name} is valid! ({version_count} versions)")
            sys.exit(0)


if __name__ == "__main__":
    main()
