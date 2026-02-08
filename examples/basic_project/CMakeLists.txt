cmake_minimum_required(VERSION 3.14)
project(my_app VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================================
# Option 1: Include CCR from local path (development)
# ============================================================================
# include(${CMAKE_CURRENT_SOURCE_DIR}/../cmake/CCR.cmake)

# ============================================================================
# Option 2: Fetch CCR from GitHub (recommended for projects)
# ============================================================================
include(FetchContent)
FetchContent_Declare(
  ccr
  GIT_REPOSITORY https://github.com/your-org/cmake-central-registry
  GIT_TAG main
  SOURCE_SUBDIR cmake  # Only need the cmake folder
)
FetchContent_MakeAvailable(ccr)
include(${ccr_SOURCE_DIR}/cmake/CCR.cmake)

# ============================================================================
# Add packages from the registry
# ============================================================================

# Simple usage - uses default version
ccr_add_package(nlohmann_json)

# Specify version explicitly
ccr_add_package(fmt VERSION 10.1.0)

# spdlog depends on fmt - CCR handles this automatically
# Since fmt is already loaded, it won't be fetched again
ccr_add_package(spdlog VERSION 1.12.0)

# Add testing framework
ccr_add_package(catch2 VERSION 3.5.2)

# ============================================================================
# Show what's available (optional, for debugging)
# ============================================================================
# ccr_list_packages()
# ccr_package_info(fmt)

# ============================================================================
# Create executable
# ============================================================================
add_executable(my_app src/main.cpp)

target_link_libraries(my_app 
  PRIVATE 
    fmt::fmt
    spdlog::spdlog
    nlohmann_json::nlohmann_json
)

# ============================================================================
# Tests
# ============================================================================
enable_testing()

add_executable(my_app_tests tests/test_main.cpp)
target_link_libraries(my_app_tests PRIVATE Catch2::Catch2WithMain)

include(Catch)
catch_discover_tests(my_app_tests)

# ============================================================================
# Generate lockfile for reproducible builds
# ============================================================================
ccr_generate_lockfile("${CMAKE_CURRENT_SOURCE_DIR}/ccr.lock")
