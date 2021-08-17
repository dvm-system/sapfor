#
# Copyright 2018 DVM System Group
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.4.3)
project(SAPFOR VERSION 3.0.0 LANGUAGES CXX)

set(SAPFOR_VERSION_SUFFIX "alpha.2")
set(SAPFOR_VERSION "${SAPFOR_VERSION}-${SAPFOR_VERSION_SUFFIX}")

set(SAPFOR_DESCRIPTION "System FOR Automate Parallelization")
set(SAPFOR_HOMEPAGE_URL "http://dvm-system.org/")

option(BUILD_APC "Build automated parallelizing compiler" OFF)
option(BUILD_DYNA "Build dynmaic analyzer runtime" OFF)
option(BUILD_lp_solve "Build Mixed Integer Linear Programming (MILP) solver" OFF)
option(BUILD_ADVISOR "Build Microsoft Visual Studio Code extension" OFF)

set (TSAR_FOLDER "Tools" CACHE STRING "Specify IDE folder for TSAR.")

if(BUILD_TESTING)
  enable_testing()
  add_subdirectory(utils)
endif()

if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/bcl/CMakeLists.txt)
  add_subdirectory(bcl)
  set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_BINARY_DIR}/bcl ${CMAKE_PREFIX_PATH})
else()
  message(WARNING "Configure without BCL: sources are not available")
endif()

if(BUILD_APC)
  set(BUILD_APC_C ON)
  set(APC_CORE_FOLDER "APC libraries"
    CACHE STRING "Specify IDE folder for APC core library.")
  set(APC_LIBRARY_FOLDER "APC libraries"
    CACHE STRING "Specify IDE folder for APC internal libraries.")
  add_subdirectory(experts/apc)
  set(CMAKE_PREFIX_PATH
    ${CMAKE_CURRENT_BINARY_DIR}/experts/apc ${CMAKE_PREFIX_PATH})
endif()

if(BUILD_lp_solve)
  set(lp_solve_FOLDER "lp_solve libraries"
    CACHE STRING "Specify IDE folder for lp_solve library.")
  add_subdirectory(lp_solve)
  set(CMAKE_PREFIX_PATH
    ${CMAKE_CURRENT_BINARY_DIR}/lp_solve ${CMAKE_PREFIX_PATH})
endif()

add_subdirectory(analyzers)
add_subdirectory(gui)

get_property(TSAR_VERSION_BUILD GLOBAL PROPERTY TSAR_VERSION_BUILD)
if (TSAR_VERSION_BUILD)
  set(SAPFOR_VERSION "${SAPFOR_VERSION}+${TSAR_VERSION_BUILD}")
endif()

# All internal packages should populate their root paths in this property.
# We add these paths at the begining of CMAKE_PREFIX_PATH
# to make find_package() uses their first.
get_property(PACKAGE_PREFIX_PATH GLOBAL PROPERTY PACKAGE_PREFIX_PATH)
list(PREPEND CMAKE_PREFIX_PATH ${PACKAGE_PREFIX_PATH})
add_subdirectory(extensions)

if (NOT TARGET tsar)
  return()
endif()

# Configure CPack.
# Configure it here to overwrite configuration inside LLVM directory (if LLVM is build with SAPFOR).
set(CPACK_PACKAGE_INSTALL_DIRECTORY "SAPFOR")
set(CPACK_PACKAGE_VENDOR "DVM System")
set(CPACK_PACKAGE_HOMEPAGE_URL ${SAPFOR_HOMEPAGE_URL})
set(CPACK_PACKAGE_VERSION_MAJOR ${SAPFOR_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${SAPFOR_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${SAPFOR_VERSION_PATCH})
set(CPACK_PACKAGE_VERSION ${SAPFOR_VERSION})
set(CPACK_MONOLITHIC_INSTALL TRUE)
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "System FOR Automated Parallelization")
set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/analyzers/tsar/LICENSE.txt")
set(CPACK_NSIS_COMPRESSOR "/SOLID lzma \r\n SetCompressorDictSize 32")
if(WIN32 AND NOT UNIX)
  set(CPACK_PACKAGE_INSTALL_REGISTRY_KEY "SAPFOR")
  set(CPACK_PACKAGE_ICON "${CMAKE_CURRENT_SOURCE_DIR}\\\\cmake\\\\dvm-logo.bmp")
  set(CPACK_NSIS_MUI_ICON "${CMAKE_CURRENT_SOURCE_DIR}\\\\cmake\\\\spf-logo.ico")
  set(CPACK_NSIS_MUI_UNIICON "${CMAKE_CURRENT_SOURCE_DIR}\\\\cmake\\\\spf-logo.ico")
  set(CPACK_NSIS_MODIFY_PATH "ON")
  set(CPACK_NSIS_ENABLE_UNINSTALL_BEFORE_INSTALL "ON")
  if(CMAKE_CL_64 )
    set(CPACK_NSIS_INSTALL_ROOT "$PROGRAMFILES64")
  endif()
  # EnVar plug-in for NSIS is used to update LIB environment variable.
  set(CPACK_NSIS_EXTRA_INSTALL_COMMANDS "
    StrCmp \\\$DO_NOT_ADD_TO_PATH \\\"1\\\" doNotAddToPath
      StrCmp \\\$ADD_TO_PATH_ALL_USERS \\\"1\\\" 0 +2
        EnVar::SetHKLM
      EnVar::AddValueEx \\\"LIB\\\" \\\"\\\$INSTDIR\\\\lib\\\"
    doNotAddToPath:
  ")
  set(CPACK_NSIS_EXTRA_UNINSTALL_COMMANDS "
    StrCmp \\\$DO_NOT_ADD_TO_PATH \\\"1\\\" gotoEnd
      StrCmp \\\$ADD_TO_PATH_ALL_USERS \\\"1\\\" 0 +2
        EnVar::SetHKLM
      EnVar::Check \\\"LIB\\\" \\\"NULL\\\"
      Pop \\\$0
      StrCmp \\\$0 \\\"0\\\" 0 gotoEnd
        EnVar::DeleteValue \\\"LIB\\\" \\\"\\\$INSTDIR\\\\lib\\\"
        StrCmp \\\$ADD_TO_PATH_ALL_USERS \\\"1\\\" 0 +3
          ReadRegStr \\\$1 \\\${NT_all_env} \\\"LIB\\\"
          Goto +2
          ReadRegStr \\\$1 \\\${NT_current_env} \\\"LIB\\\"
        StrCmp \\\$1 \\\"\\\" 0 gotoEnd
          EnVar::Delete \\\"LIB\\\"
    gotoEnd:
  ")
endif()
include(CPack)
