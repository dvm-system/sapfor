file(GLOB CHILD_LIST RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} *)
foreach(C ${CHILD_LIST})
  if (IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${C} AND
      EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/${C}/CMakeLists.txt)
    add_subdirectory(${C})
  endif()
endforeach()
