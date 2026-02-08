cmake_minimum_required(VERSION 3.14)
project(my_app VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================================
# Dependencies (managed in separate file for cleaner organization)
# ============================================================================
include(cmake/Dependencies.cmake)
my_app_setup_dependencies()

# ============================================================================
# Create executable
# ============================================================================
add_executable(my_app src/main.cpp)

target_link_libraries(my_app 
  PRIVATE 
    spdlog::spdlog_header_only
    nlohmann_json::nlohmann_json
)

# ============================================================================
# Tests
# ============================================================================
enable_testing()

add_executable(my_app_tests tests/test_main.cpp)
target_link_libraries(my_app_tests PRIVATE Catch2::Catch2WithMain)

# Include Catch2's CMake integration from its source directory
include(${Catch2_SOURCE_DIR}/extras/Catch.cmake)
catch_discover_tests(my_app_tests)

# ============================================================================
# Generate lockfile for reproducible builds
# ============================================================================
ccr_generate_lockfile("${CMAKE_CURRENT_SOURCE_DIR}/ccr.lock")
