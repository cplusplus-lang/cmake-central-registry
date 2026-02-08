# Dependencies.cmake
# Centralized dependency management using CMake Central Registry (CCR)
#
# Done as a function so that updates to variables like
# CMAKE_CXX_FLAGS don't propagate out to other targets

include(${CMAKE_CURRENT_LIST_DIR}/../../../cmake/CCR.cmake)
function(demo_setup_dependencies)

  # For each dependency, check if it's already been provided
  # by a parent project before adding from the registry

  if(NOT TARGET fmt::fmt)
    ccr_add_package(fmt VERSION 10.1.0)
  endif()

  # spdlog depends on fmt - since fmt is already loaded above,
  # CCR will detect it and not fetch a duplicate
  if(NOT TARGET spdlog::spdlog)
    ccr_add_package(spdlog VERSION 1.12.0)
  endif()

endfunction()
