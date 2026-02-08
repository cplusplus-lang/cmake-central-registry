# CMake Central Registry (CCR)

A lightweight, CMake-native package registry built on top of [CPM.cmake](https://github.com/cpm-cmake/CPM.cmake).

## Philosophy

- **Zero dependencies**: Just CMake, no Python/Ruby/etc.
- **Curated packages**: Quality over quantity
- **Source-based**: Build from source with your toolchain
- **Simple API**: `ccr_add_package(fmt VERSION 10.1.0)`

## Quick Start

```cmake
# In your CMakeLists.txt
include(FetchContent)
FetchContent_Declare(
  ccr
  GIT_REPOSITORY https://github.com/your-org/cmake-central-registry
  GIT_TAG v1.0.0
)
FetchContent_MakeAvailable(ccr)

# Now use packages from the registry
ccr_add_package(fmt VERSION 10.1.0)
ccr_add_package(spdlog VERSION 1.12.0)
ccr_add_package(nlohmann_json VERSION 3.11.3)

target_link_libraries(my_app PRIVATE fmt::fmt spdlog::spdlog nlohmann_json::nlohmann_json)
```

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                    Your CMakeLists.txt                      │
│                                                             │
│  ccr_add_package(fmt VERSION 10.1.0)                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  CCR Module (CCR.cmake)                     │
│                                                             │
│  1. Lookup package in registry/packages/*.json              │
│  2. Resolve version → git tag/commit                        │
│  3. Check for conflicts with already-added packages         │
│  4. Forward to CPM.cmake with validated parameters          │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                      CPM.cmake                              │
│                                                             │
│  - FetchContent wrapper with caching                        │
│  - Handles git clone, extraction, caching                   │
└─────────────────────────────────────────────────────────────┘
```

## Registry Format

Each package has a JSON file in `registry/packages/`:

```json
{
  "name": "fmt",
  "description": "A modern formatting library",
  "homepage": "https://fmt.dev",
  "repository": "https://github.com/fmtlib/fmt",
  "versions": {
    "10.1.0": {
      "git_tag": "10.1.0",
      "sha256": "optional-archive-hash",
      "cmake_options": {},
      "patches": []
    }
  },
  "targets": ["fmt::fmt", "fmt::fmt-header-only"],
  "dependencies": []
}
```

## Features

- [x] Simple package lookup
- [x] Version validation
- [x] Dependency tracking
- [x] Conflict detection
- [x] Lockfile generation
- [ ] Binary caching (planned)
- [ ] Package search CLI (planned)

## Contributing a Package

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on adding packages to the registry.
