# SPDX-License-Identifier: MIT
# CMake Central Registry (CCR) - Main module
# https://github.com/your-org/cmake-central-registry

cmake_minimum_required(VERSION 3.14)

if(CCR_INCLUDED)
  return()
endif()
set(CCR_INCLUDED TRUE)

# ============================================================================
# Configuration
# ============================================================================

set(CCR_VERSION "1.0.0")
set(CCR_SOURCE_DIR "${CMAKE_CURRENT_LIST_DIR}/..")
set(CCR_REGISTRY_DIR "${CCR_SOURCE_DIR}/registry/packages")

# Cache for loaded packages (prevent duplicates)
set_property(GLOBAL PROPERTY CCR_LOADED_PACKAGES "")
set_property(GLOBAL PROPERTY CCR_PACKAGE_VERSIONS "")

# ============================================================================
# Include CPM.cmake (fetched automatically if not present)
# ============================================================================

if(NOT DEFINED CPM_DOWNLOAD_VERSION)
  set(CPM_DOWNLOAD_VERSION 0.40.0)
endif()

if(NOT DEFINED CPM_SOURCE_CACHE)
  set(CPM_SOURCE_CACHE "${CMAKE_SOURCE_DIR}/.cpm_cache" CACHE PATH "CPM source cache directory")
endif()

set(CPM_DOWNLOAD_LOCATION "${CMAKE_BINARY_DIR}/cmake/CPM_${CPM_DOWNLOAD_VERSION}.cmake")

if(NOT EXISTS ${CPM_DOWNLOAD_LOCATION})
  message(STATUS "[CCR] Downloading CPM.cmake v${CPM_DOWNLOAD_VERSION}")
  file(DOWNLOAD
    "https://github.com/cpm-cmake/CPM.cmake/releases/download/v${CPM_DOWNLOAD_VERSION}/CPM.cmake"
    ${CPM_DOWNLOAD_LOCATION}
    SHOW_PROGRESS
  )
endif()

include(${CPM_DOWNLOAD_LOCATION})

# ============================================================================
# JSON Parsing Utilities (CMake 3.19+ has native JSON support)
# ============================================================================

# Simple JSON value extractor using string operations
# For CMake < 3.19, we use regex. For 3.19+, we use string(JSON)
function(_ccr_json_get_string json_content key out_var)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
    string(JSON value ERROR_VARIABLE err GET "${json_content}" "${key}")
    if(NOT err)
      set(${out_var} "${value}" PARENT_SCOPE)
    else()
      set(${out_var} "" PARENT_SCOPE)
    endif()
  else()
    # Fallback regex parsing for older CMake
    string(REGEX MATCH "\"${key}\"[[:space:]]*:[[:space:]]*\"([^\"]+)\"" match "${json_content}")
    if(CMAKE_MATCH_1)
      set(${out_var} "${CMAKE_MATCH_1}" PARENT_SCOPE)
    else()
      set(${out_var} "" PARENT_SCOPE)
    endif()
  endif()
endfunction()

function(_ccr_json_get_object json_content key out_var)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
    string(JSON value ERROR_VARIABLE err GET "${json_content}" "${key}")
    if(NOT err)
      set(${out_var} "${value}" PARENT_SCOPE)
    else()
      set(${out_var} "" PARENT_SCOPE)
    endif()
  else()
    set(${out_var} "" PARENT_SCOPE)
    message(WARNING "[CCR] Full JSON parsing requires CMake 3.19+")
  endif()
endfunction()

# ============================================================================
# Registry Functions
# ============================================================================

# Load package metadata from registry (BCR-style folder structure)
function(_ccr_load_package_metadata package_name out_var)
  set(package_dir "${CCR_REGISTRY_DIR}/${package_name}")
  set(metadata_file "${package_dir}/metadata.json")
  
  if(NOT EXISTS "${metadata_file}")
    message(FATAL_ERROR "[CCR] Package '${package_name}' not found in registry. "
      "Available packages are in: ${CCR_REGISTRY_DIR}")
  endif()
  
  file(READ "${metadata_file}" json_content)
  set(${out_var} "${json_content}" PARENT_SCOPE)
endfunction()

# Load version-specific source info (BCR-style)
function(_ccr_load_source_info package_name version out_var)
  set(source_file "${CCR_REGISTRY_DIR}/${package_name}/${version}/source.json")
  
  if(NOT EXISTS "${source_file}")
    message(FATAL_ERROR "[CCR] Version '${version}' of package '${package_name}' not found. "
      "Expected: ${source_file}")
  endif()
  
  file(READ "${source_file}" json_content)
  set(${out_var} "${json_content}" PARENT_SCOPE)
endfunction()

# Check if package is already loaded
function(_ccr_is_package_loaded package_name out_var)
  get_property(loaded_packages GLOBAL PROPERTY CCR_LOADED_PACKAGES)
  list(FIND loaded_packages "${package_name}" index)
  if(index GREATER_EQUAL 0)
    set(${out_var} TRUE PARENT_SCOPE)
  else()
    set(${out_var} FALSE PARENT_SCOPE)
  endif()
endfunction()

# Mark package as loaded
function(_ccr_mark_package_loaded package_name version)
  set_property(GLOBAL APPEND PROPERTY CCR_LOADED_PACKAGES "${package_name}")
  set_property(GLOBAL PROPERTY "CCR_PKG_VERSION_${package_name}" "${version}")
endfunction()

# Get version info from source.json (BCR-style)
function(_ccr_get_version_info package_name version out_git_tag out_cmake_options)
  _ccr_load_source_info("${package_name}" "${version}" source_content)
  
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
    string(JSON git_tag GET "${source_content}" "git_tag")
    set(${out_git_tag} "${git_tag}" PARENT_SCOPE)
    
    # Extract cmake_options
    string(JSON cmake_opts_obj ERROR_VARIABLE err GET "${source_content}" "cmake_options")
    if(NOT err)
      string(JSON num_keys LENGTH "${cmake_opts_obj}")
      set(options_list "")
      if(num_keys GREATER 0)
        math(EXPR last_index "${num_keys} - 1")
        foreach(i RANGE 0 ${last_index})
          string(JSON key MEMBER "${cmake_opts_obj}" ${i})
          string(JSON val GET "${cmake_opts_obj}" "${key}")
          list(APPEND options_list "${key}=${val}")
        endforeach()
      endif()
      set(${out_cmake_options} "${options_list}" PARENT_SCOPE)
    else()
      set(${out_cmake_options} "" PARENT_SCOPE)
    endif()
  else()
    # Simplified fallback - just extract git_tag
    _ccr_json_get_string("${source_content}" "git_tag" git_tag)
    set(${out_git_tag} "${git_tag}" PARENT_SCOPE)
    set(${out_cmake_options} "" PARENT_SCOPE)
  endif()
endfunction()

# Get repository URL
function(_ccr_get_repository_url json_content out_var)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
    string(JSON repo_obj GET "${json_content}" "repository")
    string(JSON url GET "${repo_obj}" "url")
    set(${out_var} "${url}" PARENT_SCOPE)
  else()
    _ccr_json_get_string("${json_content}" "url" url)
    set(${out_var} "${url}" PARENT_SCOPE)
  endif()
endfunction()

# Get default version
function(_ccr_get_default_version json_content out_var)
  _ccr_json_get_string("${json_content}" "default_version" version)
  set(${out_var} "${version}" PARENT_SCOPE)
endfunction()

# Get dependencies
function(_ccr_get_dependencies json_content out_var)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.19")
    string(JSON deps_array ERROR_VARIABLE err GET "${json_content}" "dependencies")
    if(err)
      set(${out_var} "" PARENT_SCOPE)
      return()
    endif()
    
    string(JSON num_deps LENGTH "${deps_array}")
    set(deps_list "")
    if(num_deps GREATER 0)
      math(EXPR last_index "${num_deps} - 1")
      foreach(i RANGE 0 ${last_index})
        string(JSON dep_obj GET "${deps_array}" ${i})
        string(JSON dep_name GET "${dep_obj}" "name")
        string(JSON dep_version ERROR_VARIABLE verr GET "${dep_obj}" "version_constraint")
        if(NOT verr)
          list(APPEND deps_list "${dep_name}:${dep_version}")
        else()
          list(APPEND deps_list "${dep_name}")
        endif()
      endforeach()
    endif()
    set(${out_var} "${deps_list}" PARENT_SCOPE)
  else()
    set(${out_var} "" PARENT_SCOPE)
  endif()
endfunction()

# ============================================================================
# Main Public API
# ============================================================================

#[[
  ccr_add_package(<package_name>
    [VERSION <version>]
    [OPTIONS <option1> <option2> ...]
    [SKIP_DEPENDENCIES]
  )
  
  Add a package from the CMake Central Registry.
  
  Arguments:
    package_name     - Name of the package (must exist in registry/packages/)
    VERSION          - Specific version to use (defaults to package's default_version)
    OPTIONS          - Additional CMake options to pass (overrides registry defaults)
    SKIP_DEPENDENCIES - Don't automatically fetch dependencies
    
  Example:
    ccr_add_package(fmt VERSION 10.1.0)
    ccr_add_package(spdlog VERSION 1.12.0 OPTIONS SPDLOG_FMT_EXTERNAL=ON)
]]
function(ccr_add_package package_name)
  # Parse arguments
  set(options SKIP_DEPENDENCIES)
  set(oneValueArgs VERSION)
  set(multiValueArgs OPTIONS)
  cmake_parse_arguments(ARG "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})
  
  # Check if already loaded
  _ccr_is_package_loaded("${package_name}" is_loaded)
  if(is_loaded)
    get_property(loaded_version GLOBAL PROPERTY "CCR_PKG_VERSION_${package_name}")
    if(ARG_VERSION AND NOT "${ARG_VERSION}" STREQUAL "${loaded_version}")
      message(WARNING "[CCR] Package '${package_name}' already loaded with version ${loaded_version}, "
        "ignoring request for version ${ARG_VERSION}")
    endif()
    return()
  endif()
  
  # Load package metadata
  _ccr_load_package_metadata("${package_name}" json_content)
  
  # Determine version
  if(NOT ARG_VERSION)
    _ccr_get_default_version("${json_content}" ARG_VERSION)
    message(STATUS "[CCR] Using default version ${ARG_VERSION} for ${package_name}")
  endif()
  
  # Get repository URL
  _ccr_get_repository_url("${json_content}" repo_url)
  
  # Get version-specific info (from source.json)
  _ccr_get_version_info("${package_name}" "${ARG_VERSION}" git_tag cmake_options)
  
  # Handle dependencies first (unless skipped)
  if(NOT ARG_SKIP_DEPENDENCIES)
    _ccr_get_dependencies("${json_content}" dependencies)
    foreach(dep IN LISTS dependencies)
      # Parse dependency string (name:version_constraint)
      string(FIND "${dep}" ":" colon_pos)
      if(colon_pos GREATER 0)
        string(SUBSTRING "${dep}" 0 ${colon_pos} dep_name)
        # For now, just use the dependency's default version
        # TODO: Implement version constraint resolution
        ccr_add_package("${dep_name}")
      else()
        ccr_add_package("${dep}")
      endif()
    endforeach()
  endif()
  
  # Build CPM options list
  set(cpm_options "")
  foreach(opt IN LISTS cmake_options)
    list(APPEND cpm_options "OPTIONS" "${opt}")
  endforeach()
  
  # Add user-provided options (override registry defaults)
  foreach(opt IN LISTS ARG_OPTIONS)
    list(APPEND cpm_options "OPTIONS" "${opt}")
  endforeach()
  
  # Call CPM
  message(STATUS "[CCR] Adding ${package_name}@${ARG_VERSION} from ${repo_url}")
  
  CPMAddPackage(
    NAME ${package_name}
    GIT_REPOSITORY ${repo_url}
    GIT_TAG ${git_tag}
    ${cpm_options}
  )
  
  # Mark as loaded
  _ccr_mark_package_loaded("${package_name}" "${ARG_VERSION}")
endfunction()

# ============================================================================
# Utility Functions
# ============================================================================

# List all available packages (BCR-style folder structure)
function(ccr_list_packages)
  file(GLOB package_dirs "${CCR_REGISTRY_DIR}/*")
  message(STATUS "[CCR] Available packages:")
  foreach(pkg_dir IN LISTS package_dirs)
    if(IS_DIRECTORY "${pkg_dir}")
      get_filename_component(pkg_name "${pkg_dir}" NAME)
      set(metadata_file "${pkg_dir}/metadata.json")
      
      if(EXISTS "${metadata_file}")
        file(READ "${metadata_file}" json_content)
        _ccr_json_get_string("${json_content}" "description" description)
        _ccr_get_default_version("${json_content}" default_ver)
        
        message(STATUS "  - ${pkg_name} (${default_ver}): ${description}")
      endif()
    endif()
  endforeach()
endfunction()

# Show package info
function(ccr_package_info package_name)
  _ccr_load_package_metadata("${package_name}" json_content)
  
  _ccr_json_get_string("${json_content}" "description" description)
  _ccr_json_get_string("${json_content}" "homepage" homepage)
  _ccr_json_get_string("${json_content}" "license" license)
  _ccr_get_default_version("${json_content}" default_ver)
  _ccr_get_repository_url("${json_content}" repo_url)
  
  message(STATUS "")
  message(STATUS "[CCR] Package: ${package_name}")
  message(STATUS "  Description: ${description}")
  message(STATUS "  Homepage: ${homepage}")
  message(STATUS "  License: ${license}")
  message(STATUS "  Repository: ${repo_url}")
  message(STATUS "  Default version: ${default_ver}")
  message(STATUS "")
endfunction()

# Generate lockfile
function(ccr_generate_lockfile output_file)
  get_property(loaded_packages GLOBAL PROPERTY CCR_LOADED_PACKAGES)
  
  set(lockfile_content "# CCR Lockfile - Generated ${CMAKE_CURRENT_TIMESTAMP}\n")
  string(APPEND lockfile_content "# Do not edit manually\n\n")
  
  foreach(pkg IN LISTS loaded_packages)
    get_property(version GLOBAL PROPERTY "CCR_PKG_VERSION_${pkg}")
    string(APPEND lockfile_content "${pkg}=${version}\n")
  endforeach()
  
  file(WRITE "${output_file}" "${lockfile_content}")
  message(STATUS "[CCR] Lockfile written to ${output_file}")
endfunction()

message(STATUS "[CCR] CMake Central Registry v${CCR_VERSION} loaded")
