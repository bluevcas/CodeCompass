include_directories(
  include
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
  ${PROJECT_SOURCE_DIR}/util/include
  ${PROJECT_SOURCE_DIR}/webserver/include)

include_directories(SYSTEM
  ${THRIFT_LIBTHRIFT_INCLUDE_DIRS})

add_custom_command(
  OUTPUT
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/DummyService.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/DummyService.h
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
  COMMAND
    ${THRIFT_EXECUTABLE} --gen cpp
      -o ${CMAKE_CURRENT_BINARY_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/dummy.thrift
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/dummy.thrift
  COMMENT
    "Generating Thrift for dummy.thrift")

add_library(dummythrift STATIC
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/DummyService.cpp)

# 根据编译器类型设置适当的编译选项
if(MSVC)
  target_compile_options(dummythrift PUBLIC /EHsc)
else()
  target_compile_options(dummythrift PUBLIC -fPIC)
endif()

add_library(dummyservice SHARED
  src/dummyservice.cpp
  src/plugin.cpp)

if(MSVC)
  target_compile_options(dummyservice PUBLIC /EHsc)
else()
  target_compile_options(dummyservice PUBLIC -Wno-unknown-pragmas)
endif()

target_link_libraries(dummyservice
  util
  ${THRIFT_LIBTHRIFT_LIBRARIES}
  ${ODB_LIBRARIES}
  dummythrift)

install(TARGETS dummyservice DESTINATION ${INSTALL_SERVICE_DIR})
