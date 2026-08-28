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
set(PROJECT_OBJECTS ${PROJECT_OBJECTS} "postgis_mest.c")

add_library(postgis_mest MODULE ${PROJECT_OBJECTS})
set_target_properties(postgis_mest PROPERTIES PREFIX "")

install(
  FILES "${CMAKE_SOURCE_DIR}/postgis_mest.control" "${CMAKE_SOURCE_DIR}/postgis_mest--1.0.sql"
  DESTINATION "${POSTGRESQL_SHARE_DIR}/extension")
install(TARGETS postgis_mest DESTINATION "${POSTGRESQL_DYNLIB_DIR}")

#-------------------------------------
# Regression tests
#-------------------------------------

execute_process(
  COMMAND ${POSTGRESQL_PG_CONFIG} --pgxs
  OUTPUT_STRIP_TRAILING_WHITESPACE
  OUTPUT_VARIABLE POSTGRESQL_PGXS)
get_filename_component(POSTGRESQL_PGXS_DIR "${POSTGRESQL_PGXS}" DIRECTORY)
find_program(PG_REGRESS NAMES pg_regress
  HINTS "${POSTGRESQL_PGXS_DIR}/../test/regress")

file(GLOB TEST_FILES "${CMAKE_SOURCE_DIR}/sql/*.test.sql")
set(TEST_NAMES "")
foreach(TEST_FILE ${TEST_FILES})
  get_filename_component(TEST_NAME "${TEST_FILE}" NAME)
  string(REGEX REPLACE "\\.sql$" "" TEST_NAME "${TEST_NAME}")
  list(APPEND TEST_NAMES "${TEST_NAME}")
endforeach()
list(SORT TEST_NAMES)

# Runs the tests against a server already holding the installed extension,
# taking PGHOST, PGPORT and PGUSER from the environment
add_custom_target(installcheck
  COMMAND ${PG_REGRESS} --inputdir=${CMAKE_SOURCE_DIR}
    --outputdir=${CMAKE_CURRENT_BINARY_DIR}
    --bindir=${POSTGRESQL_BIN_DIR}
    --dbname=contrib_regression ${TEST_NAMES}
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
