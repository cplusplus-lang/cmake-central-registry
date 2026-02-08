# Dependencies.cmake
# Centralized dependency management using CMake Central Registry (CCR)
#
# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other targets

include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/CCR.cmake)

function(my_app_setup_dependencies)

  # For each dependency, check if it's already been provided
  # by a parent project before adding from the registry

  if(NOT TARGET nlohmann_json::nlohmann_json)
    ccr_add_package(nlohmann_json)
  endif()

  # spdlog provides fmt via its bundled copy when using spdlog_header_only
  if(NOT TARGET spdlog::spdlog)
    ccr_add_package(spdlog VERSION 1.12.0)
  endif()

  if(NOT TARGET Catch2::Catch2WithMain)
    ccr_add_package(catch2 VERSION 3.5.2)
  endif()

endfunction()
