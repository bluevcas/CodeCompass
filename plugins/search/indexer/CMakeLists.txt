include_directories(
  include
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
  ${PROJECT_SOURCE_DIR}/util/include)

include_directories(SYSTEM
  ${THRIFT_LIBTHRIFT_INCLUDE_DIRS})

add_custom_command(
  OUTPUT
    # C++ 文件
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/searchindexer_constants.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/searchindexer_types.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/IndexerService.cpp
    # 目录
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java
    # Java 文件（明确列出）
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/FieldValue.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/IndexerService.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/Location.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/searchindexerConstants.java
  COMMAND
    ${THRIFT_EXECUTABLE} --gen cpp --gen java
      -o ${CMAKE_CURRENT_BINARY_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/searchindexer.thrift
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/searchindexer.thrift
  COMMENT
    "Generating Thrift for searchindexer.thrift")

add_library(searchindexerthrift STATIC
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/searchindexer_constants.cpp
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/searchindexer_types.cpp
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/IndexerService.cpp)

# 根据编译器类型设置适当的编译选项
if(MSVC)
  target_compile_options(searchindexerthrift PUBLIC /EHsc)
else()
  target_compile_options(searchindexerthrift PUBLIC -fPIC)
endif()

# Create java library from thrift files
set(CMAKE_JAVA_INCLUDE_PATH ${PROJECT_SOURCE_DIR}/lib/java/*)

add_jar(searchindexerthriftjava
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/FieldValue.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/IndexerService.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/Location.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/searchindexerConstants.java
  OUTPUT_NAME searchindexerthrift)

# 确保 Java 文件在 JAR 构建前生成
add_custom_target(generate_searchindexer_java_thrift
  DEPENDS 
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/FieldValue.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/IndexerService.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/Location.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/parser/search/searchindexerConstants.java)
add_dependencies(searchindexerthriftjava generate_searchindexer_java_thrift)

# Java indexer
add_subdirectory(indexer-java)

# Create indexer service library
add_library(indexerservice SHARED
  src/indexerprocess.cpp)

target_link_libraries(indexerservice
  util
  searchindexerthrift
  ${THRIFT_LIBTHRIFT_LIBRARIES}
  ${Boost_LIBRARIES})

install(TARGETS indexerservice DESTINATION ${INSTALL_LIB_DIR})
install_jar(searchindexerthriftjava ${INSTALL_JAVA_LIB_DIR})
