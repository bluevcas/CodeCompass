# 跨平台编译器选项宏
macro(add_cross_platform_compile_options target)
  if(MSVC)
    # MSVC 编译器选项
    target_compile_options(${target} PUBLIC /EHsc)
  else()
    # GCC/Clang 编译器选项
    target_compile_options(${target} PUBLIC -Wno-unknown-pragmas -fPIC)
  endif()
endmacro()

# Generate ODB files from sources
# @return ODB_CXX_SOURCES - odb cxx source files
function(generate_odb_files _src)
  set(DEPENDENCY_PLUGIN_INCLUDE_DIRS ${ARGN})
  list(TRANSFORM DEPENDENCY_PLUGIN_INCLUDE_DIRS PREPEND "-I${CMAKE_SOURCE_DIR}/plugins/")
  list(TRANSFORM DEPENDENCY_PLUGIN_INCLUDE_DIRS APPEND "/model/include")

  foreach(_file ${_src})
    get_filename_component(_dir ${_file} DIRECTORY)
    get_filename_component(_name ${_file} NAME)

    string(REPLACE ".h" "-odb.cxx" _cxx ${_name})
    string(REPLACE ".h" "-odb.hxx" _hxx ${_name})
    string(REPLACE ".h" "-odb.ixx" _ixx ${_name})
    string(REPLACE ".h" "-odb.sql" _sql ${_name})

    add_custom_command(
      OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/${_cxx}
        ${CMAKE_CURRENT_BINARY_DIR}/include/model/${_hxx}
        ${CMAKE_CURRENT_BINARY_DIR}/include/model/${_ixx}
        ${CMAKE_CURRENT_BINARY_DIR}/include/model/${_sql}
      COMMAND
        ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/include/model
      COMMAND
        ${ODB_EXECUTABLE} ${ODBFLAGS}
          -o ${CMAKE_CURRENT_BINARY_DIR}/include/model
          -I ${CMAKE_CURRENT_SOURCE_DIR}/include
          -I ${CMAKE_SOURCE_DIR}/model/include
          -I ${CMAKE_SOURCE_DIR}/util/include
          -I ${ODB_INCLUDE_DIRS}
          --include-regex '%util/odb_compatibility.h%'
          ${DEPENDENCY_PLUGIN_INCLUDE_DIRS}
          ${CMAKE_CURRENT_SOURCE_DIR}/${_file}
      COMMAND
        ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_BINARY_DIR}/include/model/${_cxx} ${CMAKE_CURRENT_BINARY_DIR}
      COMMAND
        ${CMAKE_COMMAND} -E remove ${CMAKE_CURRENT_BINARY_DIR}/include/model/${_cxx}
      DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/${_file}
      COMMENT "Generating ODB for ${_file}")

    list(APPEND SOURCES ${_cxx})
  endforeach(_file)

  set(ODB_CXX_SOURCES ${SOURCES} PARENT_SCOPE)
endfunction(generate_odb_files)

# Add a new static library target that links against ODB.
function(add_odb_library _name)
  add_library(${_name} STATIC ${ARGN})
  # 使用跨平台的编译器选项
  if(MSVC)
    target_compile_options(${_name} PUBLIC /EHsc)
  else()
    target_compile_options(${_name} PUBLIC -Wno-unknown-pragmas -fPIC)
  endif()
  target_link_libraries(${_name} ${ODB_LIBRARIES})
  target_include_directories(${_name} PUBLIC
    ${ODB_INCLUDE_DIRS}
    ${CMAKE_SOURCE_DIR}/util/include
    ${CMAKE_SOURCE_DIR}/model/include
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_BINARY_DIR}/include
    ${CMAKE_BINARY_DIR}/model/include)
endfunction(add_odb_library)

# This function can be used to install the ODB generated .sql files to a
# specific directory. These files will be used to create database tables before
# the parsing session.
function(install_sql)
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/include/model/
    DESTINATION ${INSTALL_SQL_DIR}
    FILES_MATCHING PATTERN "*.sql"
    PATTERN "CMakeFiles" EXCLUDE)
endfunction(install_sql)

# This function can be used to install the thrift generated .js files to a
# specific directory. These files will be used at the gui.
function(install_js_thrift)
  install(
    DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/gen-js/
    DESTINATION ${INSTALL_GEN_DIR}
    FILES_MATCHING PATTERN "*.js")
  install(
    CODE "execute_process(COMMAND ${CMAKE_SOURCE_DIR}/scripts/remover.sh WORKING_DIRECTORY ${INSTALL_GEN_DIR})")
endfunction(install_js_thrift)

# Install plugins webgui
# @parameter _dir - webgui directory of the plugin
function(install_webplugin _dir)
  # Copy javascript modules
  file(GLOB _js "${_dir}/js/[A-Z]*.js")
  install(FILES ${_js} DESTINATION "${INSTALL_SCRIPTS_DIR}/view/component" )

  # Copy javascript plugins
  file(GLOB _js "${_dir}/js/[^A-Z]*.js")
  install(FILES ${_js} DESTINATION "${INSTALL_SCRIPTS_DIR}/view" )

  # Copy css files
  file(GLOB _css "${_dir}/css/*.css")
  install(FILES ${_css} DESTINATION "${INSTALL_WEBROOT_DIR}/style" )

  # Copy images
  file(GLOB _images "${_dir}/images/*.jpg" "${_dir}/images/*.png")
  install(FILES ${_images} DESTINATION "${INSTALL_WEBROOT_DIR}/images" )

  # Collect userguides
  file(GLOB _userguides "${_dir}/userguide/*.md")
  set_property(GLOBAL APPEND PROPERTY USERGUIDES "${_userguides}")
endfunction(install_webplugin)

# Prints a coloured, and optionally bold message to the console.
# _colour should be some ANSI colour name, like "blue" or "magenta".
function(fancy_message _str _colour _isBold)
  set(BOLD_TAG "")
  set(COLOUR_TAG "")

  if (_isBold)
    set(BOLD_TAG "--bold")
  endif()

  if (NOT (_colour STREQUAL ""))
    set(COLOUR_TAG "--${_colour}")
  endif()

  execute_process(COMMAND
    ${CMAKE_COMMAND} -E env CLICOLOR_FORCE=1
    ${CMAKE_COMMAND} -E cmake_echo_color ${COLOUR_TAG} ${BOLD_TAG} ${_str})
endfunction(fancy_message)

# Joins a list of elements with a given glue string.
# See: https://stackoverflow.com/questions/7172670/best-shortest-way-to-join-a-list-in-cmake
function(join _values _glue _output)
  string (REGEX REPLACE "([^\\]|^);" "\\1${_glue}" _tmpStr "${_values}")
  string (REGEX REPLACE "[\\](.)" "\\1" _tmpStr "${_tmpStr}") #fixes escaping
  set (${_output} "${_tmpStr}" PARENT_SCOPE)
endfunction(join)