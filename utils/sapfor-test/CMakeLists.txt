cmake_minimum_required(VERSION 3.4.3)

project(SAPFOR_TEST
  VERSION 0.0.1
  LANGUAGES NONE
  DESCRIPTION "SAPFOR Testing Utility"
  HOMEPAGE_URL "https://github.com/dvm-system/sapfor")

find_package(Perl)
if (NOT PERL_FOUND)
  message(SEND_ERROR "Could NOT find Perl which is required to run tests."
                     "Disable BUILD_TESTING option or set path to Perl package.")
else()
  message(STATUS "Perl version: ${PERL_VERSION_STRING}")
endif()

set(ST_PERL_EXECUTABLE ${PERL_EXECUTABLE})
set(ST_LIBRARY_PATH "../lib/sapfor-test")

set(ST_NAME "sapfor-test")
set(ST_SCRIPT_FILE "${ST_NAME}.pl")

if (WIN32)
  set(ST_EXECUTABLE_FILE "${ST_NAME}.bat")
  set(ST_EXECUTABLE_TEMPLATE "${ST_NAME}.win.in")
else()
  set(ST_EXECUTABLE_FILE "${ST_NAME}")
  set(ST_EXECUTABLE_TEMPLATE "${ST_NAME}.uni.in")
endif()

# Substitute all @VAR@ variables except generator expressions.
configure_file(bin/${ST_EXECUTABLE_TEMPLATE} bin/${ST_EXECUTABLE_FILE} @ONLY)

# Change permissions to allow execute the configured file.
file(COPY ${CMAKE_CURRENT_BINARY_DIR}/bin/${ST_EXECUTABLE_FILE}
     DESTINATION ${CMAKE_CURRENT_SOURCE_DIR}/bin
     FILE_PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ)

install(PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/bin/${ST_SCRIPT_FILE}"
                 "${CMAKE_CURRENT_BINARY_DIR}/bin/${ST_EXECUTABLE_FILE}"
        DESTINATION bin)
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/lib/sapfor-test"
        DESTINATION lib FILES_MATCHING PATTERN *.pm)
