cmake_minimum_required(VERSION 3.14)
project(fmt_spdlog_demo VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Include CCR from parent directory
include(${CMAKE_CURRENT_SOURCE_DIR}/../../cmake/CCR.cmake)

# Add packages from registry
# Note: spdlog depends on fmt, but since we add fmt first,
# CCR will detect it's already loaded and skip the duplicate
ccr_add_package(fmt VERSION 10.1.0)
ccr_add_package(spdlog VERSION 1.12.0)

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
