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
project(SAPFOR VERSION 3.0 LANGUAGES CXX)

set(SAPFOR_DESCRIPTION "System FOR Automate Parallelization")
set(SAPFOR_HOMEPAGE_URL "http://dvm-system.org/")

option(BUILD_APC "Build automated parallelizing compiler" OFF)
option(BUILD_DYNA "Build dynmaic analyzer runtime" OFF)
option(BUILD_lp_solve "Build Mixed Integer Linear Programming (MILP) solver" OFF)

set (TSAR_FOLDER "Tools" CACHE STRING "Specify IDE folder for TSAR.")

add_subdirectory(bcl)
set(CMAKE_PREFIX_PATH ${CMAKE_CURRENT_BINARY_DIR}/bcl ${CMAKE_PREFIX_PATH})

if(BUILD_APC)
  set(APC_CORE_FOLDER "APC libraries"
    CACHE STRING "Specify IDE folder for APC core library.")
  set(APC_LIBRARY_FOLDER "APC libraries"
    CACHE STRING "Specify IDE folder for APC internal libraries.")
  add_subdirectory(experts/Sapfor_2017)
  set(CMAKE_PREFIX_PATH
    ${CMAKE_CURRENT_BINARY_DIR}/experts/Sapfor_2017 ${CMAKE_PREFIX_PATH})
endif()

if(BUILD_lp_solve)
  set(lp_solve_FOLDER "lp_solve libraries"
    CACHE STRING "Specify IDE folder for lp_solve library.")
  add_subdirectory(lp_solve)
  set(CMAKE_PREFIX_PATH
    ${CMAKE_CURRENT_BINARY_DIR}/lp_solve ${CMAKE_PREFIX_PATH})
endif()

add_subdirectory(analyzers)
