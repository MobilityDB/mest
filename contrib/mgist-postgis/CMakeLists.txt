#-------------------------------------
# MGiST-Postgis Main CMake file
#-------------------------------------

cmake_minimum_required(VERSION 3.10)

# Disallow in-source builds
if(${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR})
  message(FATAL_ERROR "In-source builds not allowed.
  Please make a new directory (called a build directory) and run CMake from there.
  You may need to remove 'CMakeCache.txt' and 'CMakeFiles/'.")
endif()

# Specify search path for CMake modules to be loaded
list(APPEND CMAKE_MODULE_PATH "${CMAKE_SOURCE_DIR}/cmake")

project(MGiST-Postgis VERSION 1.0.0)
message(STATUS "Building MGiST-Postgis version ${PROJECT_VERSION}")

# Find PostgreSQL
find_package(POSTGRESQL REQUIRED)
find_package(POSTGIS REQUIRED)
find_package(GEOS REQUIRED)
include_directories(SYSTEM ${POSTGRESQL_INCLUDE_DIR})

include_directories("${CMAKE_SOURCE_DIR}/ryu")
include_directories("${CMAKE_SOURCE_DIR}/liblwgeom")
add_subdirectory("${CMAKE_SOURCE_DIR}/liblwgeom" "liblwgeom")
add_subdirectory("${CMAKE_SOURCE_DIR}/ryu" "ryu")

set(PROJECT_OBJECTS ${PROJECT_OBJECTS} "$<TARGET_OBJECTS:ryu>")
set(PROJECT_OBJECTS ${PROJECT_OBJECTS} "$<TARGET_OBJECTS:liblwgeom>")
set(PROJECT_OBJECTS ${PROJECT_OBJECTS} "mgist_postgis.c")

add_library(mgist_postgis MODULE ${PROJECT_OBJECTS})

install(
  FILES "${CMAKE_SOURCE_DIR}/mgist_postgis.control" "${CMAKE_SOURCE_DIR}/mgist_postgis--1.0.sql"
  DESTINATION "${POSTGRESQL_SHARE_DIR}/extension")
install(TARGETS mgist_postgis DESTINATION "${POSTGRESQL_DYNLIB_DIR}")