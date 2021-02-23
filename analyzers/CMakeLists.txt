if (EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tsar/CMakeLists.txt)
  add_subdirectory(tsar)
elseif (NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/tsar/CMakeLists.txt)
  message(WARNING "Configure without TSAR: sources are not available")
endif()

if(BUILD_DYNA)
  set (DYNA_FOLDER "DYNA Runtime"
    CACHE STRING "Specify IDE folder for DYNA Runtime.")
  set(Dyna_install_path lib)
  add_subdirectory(dyna)
endif()
