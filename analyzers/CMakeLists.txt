add_subdirectory(tsar)

if(BUILD_DYNA)
  set (DYNA_FOLDER "DYNA Runtime"
    CACHE STRING "Specify IDE folder for DYNA Runtime.")
  set(Dyna_install_path ${CMAKE_INSTALL_PREFIX}/lib)
  add_subdirectory(dyna)
endif()
