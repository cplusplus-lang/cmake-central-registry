# Contributing to CMake Central Registry

Thank you for your interest in contributing packages to CCR!

## Adding a New Package

### Prerequisites

Before submitting a package, ensure it:

1. **Has a stable release** - At least one tagged version
2. **Uses CMake** - Must have a working CMakeLists.txt
3. **Exports targets** - Uses modern CMake target-based approach
4. **Has a permissive license** - MIT, BSD, Apache 2.0, BSL-1.0, etc.

### Package Specification

Create a JSON file in `registry/packages/<package_name>.json`:

```json
{
  "name": "mypackage",
  "description": "Brief description (max 100 chars)",
  "homepage": "https://example.com",
  "license": "MIT",
  "repository": {
    "type": "github",
    "url": "https://github.com/owner/repo"
  },
  "versions": {
    "1.0.0": {
      "git_tag": "v1.0.0",
      "minimum_cmake_version": "3.14",
      "tested": true,
      "cmake_options": {
        "BUILD_TESTING": "OFF",
        "BUILD_EXAMPLES": "OFF"
      }
    }
  },
  "default_version": "1.0.0",
  "targets": [
    "mypackage::mypackage"
  ],
  "dependencies": [],
  "maintainers": ["your-github-username"]
}
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Package identifier (lowercase, alphanumeric + underscore) |
| `description` | Yes | Brief description |
| `homepage` | Yes | Project homepage URL |
| `license` | Yes | SPDX license identifier |
| `repository.type` | Yes | `github`, `gitlab`, or `url` |
| `repository.url` | Yes | Git repository URL |
| `versions` | Yes | Map of version → version info |
| `default_version` | Yes | Recommended version for new users |
| `targets` | Yes | List of CMake targets the package exports |
| `dependencies` | No | List of CCR package dependencies |
| `maintainers` | Yes | GitHub usernames responsible for this entry |

### Version Info Fields

| Field | Required | Description |
|-------|----------|-------------|
| `git_tag` | Yes | Git tag or commit for this version |
| `minimum_cmake_version` | No | Minimum CMake version required |
| `tested` | Yes | Whether this version has been tested |
| `cmake_options` | No | Default CMake options to set |
| `patches` | No | List of patch files to apply |
| `notes` | No | Version-specific notes |

### Dependencies

Specify dependencies on other CCR packages:

```json
"dependencies": [
  {
    "name": "fmt",
    "version_constraint": ">=10.0.0",
    "optional": false
  }
]
```

Version constraints support:
- `>=X.Y.Z` - Minimum version
- `<X.Y.Z` - Maximum version (exclusive)
- `~X.Y.Z` - Compatible version (same major.minor)
- `^X.Y.Z` - Compatible version (same major)

## Testing Your Package

1. Fork this repository
2. Add your package JSON
3. Create a test project:

```cmake
cmake_minimum_required(VERSION 3.14)
project(test_package)

# Point to your fork
include(/path/to/your/fork/cmake/CCR.cmake)

ccr_add_package(your_package VERSION 1.0.0)

add_executable(test_app main.cpp)
target_link_libraries(test_app PRIVATE your_package::your_package)
```

4. Build and verify:

```bash
mkdir build && cd build
cmake ..
cmake --build .
```

## Pull Request Checklist

- [ ] Package JSON is valid (run `python scripts/validate.py`)
- [ ] At least one version is marked as `tested: true`
- [ ] All exported targets are listed
- [ ] Dependencies are correctly specified
- [ ] CMake options disable tests/docs/examples by default
- [ ] Package builds on Linux, macOS, and Windows
- [ ] License is OSI-approved

## Updating Existing Packages

To add a new version to an existing package:

1. Add the new version entry to the `versions` object
2. Update `default_version` if appropriate
3. Test the new version
4. Submit a PR

## Package Removal

Packages may be removed if:

- The upstream project is abandoned
- Security vulnerabilities are not addressed
- The package violates our policies

We will attempt to notify maintainers before removal.

## Code of Conduct

Please be respectful and constructive in all interactions. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
