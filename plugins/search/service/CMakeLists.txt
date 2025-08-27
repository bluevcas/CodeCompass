include_directories(
  include
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
  ${PROJECT_SOURCE_DIR}/util/include
  ${PROJECT_SOURCE_DIR}/webserver/include
  ${PROJECT_SOURCE_DIR}/model/include
  ${PROJECT_BINARY_DIR}/service/language/gen-cpp
  ${PROJECT_BINARY_DIR}/service/project/gen-cpp
  ${PLUGIN_DIR}/model/include)

include_directories(SYSTEM
  ${THRIFT_LIBTHRIFT_INCLUDE_DIRS})

# Generate thrift files
add_custom_command(
  OUTPUT
    # C++ 文件
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/search_types.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/SearchService.cpp
    # 目录
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-js
    # Java 文件（明确列出）
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/DatasourceError.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/FileSearchResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/HitCountResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/LineMatch.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/RangedHitCountResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchException.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchFilter.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchOptions.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchParams.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchRange.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchResultEntry.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchService.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchSuggestionParams.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchSuggestions.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchType.java
  COMMAND
    ${THRIFT_EXECUTABLE} --gen cpp --gen js --gen java
      -o ${CMAKE_CURRENT_BINARY_DIR}
      -I ${PROJECT_SOURCE_DIR}/service
      ${CMAKE_CURRENT_SOURCE_DIR}/search.thrift
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/search.thrift
  COMMENT
    "Generating Thrift for search.thrift")

# Create cpp static library from thrift files
add_library(searchthrift STATIC
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/search_types.cpp
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/SearchService.cpp)

# 根据编译器类型设置适当的编译选项
if(MSVC)
  target_compile_options(searchthrift PUBLIC /EHsc)
else()
  target_compile_options(searchthrift PUBLIC -fPIC)
endif()

add_dependencies(searchthrift commonthrift projectthrift)

set(CMAKE_JAVA_INCLUDE_PATH
  ${PROJECT_SOURCE_DIR}/lib/java/*
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/
  ${PROJECT_BINARY_DIR}/service/project/gen-java/)

# Create java library from thrift files
add_jar(searchthriftjava
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/DatasourceError.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/FileSearchResult.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/HitCountResult.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/LineMatch.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/RangedHitCountResult.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchException.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchFilter.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchOptions.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchParams.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchRange.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchResult.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchResultEntry.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchService.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchSuggestionParams.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchSuggestions.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchType.java
  OUTPUT_NAME searchthrift
  INCLUDE_JARS searchcommonjava)

# 确保 Java 文件在 JAR 构建前生成
add_custom_target(generate_search_service_java_thrift
  DEPENDS 
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/DatasourceError.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/FileSearchResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/HitCountResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/LineMatch.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/RangedHitCountResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchException.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchFilter.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchOptions.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchParams.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchRange.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchResult.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchResultEntry.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchService.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchSuggestionParams.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchSuggestions.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/search/SearchType.java)
add_dependencies(searchthriftjava generate_search_service_java_thrift)

# Search java
add_subdirectory(search-java)

# Create services
add_library(searchservice SHARED
  src/searchservice.cpp
  src/plugin.cpp)

target_compile_options(searchservice PUBLIC -Wno-unknown-pragmas)

target_link_libraries(searchservice
  util
  model
  mongoose
  searchthrift
  projectservice
  projectthrift
  languagethrift
  ${THRIFT_LIBTHRIFT_LIBRARIES})

install(TARGETS searchservice DESTINATION ${INSTALL_SERVICE_DIR})
install_jar(searchthriftjava ${INSTALL_JAVA_LIB_DIR})
install_js_thrift()
