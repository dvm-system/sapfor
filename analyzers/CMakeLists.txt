if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tsar/CMakeLists.txt)
  add_subdirectory(tsar)
elseif (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tsar/CMakeLists.txt)
  message(WARNING "Configure without TSAR: sources are not available")
endif()

if(BUILD_DYNA)
  set (DYNA_FOLDER "DYNA Runtime"
    CACHE STRING "Specify IDE folder for DYNA Runtime.")
  set (DYNA_TOOLS_FOLDER "Tools"
    CACHE STRING "Specify IDE folder for DYNA Tools.")
  set(Dyna_install ON)
  add_subdirectory(dyna)
endif()
