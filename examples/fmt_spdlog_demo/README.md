# fmt + spdlog Demo

Demonstrates using CCR to add fmt and spdlog to a project.

## Build

```bash
cmake -B build
cmake --build build
```

## Run

```bash
./build/demo
```

## What This Demonstrates

1. **CCR package loading** - Simple `ccr_add_package()` calls
2. **Automatic dependency handling** - spdlog depends on fmt, CCR handles this
3. **fmt features** - Formatting, colors, chrono
4. **spdlog features** - Logging levels, patterns, colored output
