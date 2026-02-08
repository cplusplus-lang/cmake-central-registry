cmake_minimum_required(VERSION 3.14)
project(fmt_spdlog_demo VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ============================================================================
# Dependencies (managed in separate file for cleaner organization)
# ============================================================================
include(cmake/Dependencies.cmake)
demo_setup_dependencies()

# Show available packages (optional)
ccr_list_packages()

# Create executable
add_executable(demo src/main.cpp)

target_link_libraries(demo 
  PRIVATE 
    fmt::fmt
    spdlog::spdlog_header_only
)

# Generate lockfile for reproducibility
ccr_generate_lockfile("${CMAKE_CURRENT_SOURCE_DIR}/ccr.lock")
