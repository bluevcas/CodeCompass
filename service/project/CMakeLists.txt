include_directories(
  include
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
  ${PROJECT_SOURCE_DIR}/model/include
  ${PROJECT_SOURCE_DIR}/util/include
  ${PROJECT_SOURCE_DIR}/webserver/include)

include_directories(SYSTEM
  ${THRIFT_LIBTHRIFT_INCLUDE_DIRS}
  ${ODB_INCLUDE_DIRS})

# 生成所有 Thrift 文件的统一命令
add_custom_command(
  OUTPUT
    # C++ 文件
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/common_constants.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/common_constants.h
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/common_types.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/common_types.h
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/project_types.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/project_types.h
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/ProjectService.cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/ProjectService.h
    # 目录
    ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-js
    # Java 文件（来自 common.thrift）
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Description.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FilePosition.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileRange.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/InvalidId.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/InvalidInput.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Position.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Range.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Timeout.java
    # Java 文件（来自 project.thrift）
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileParseStatus.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileInfo.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/MessageType.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/BuildLog.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/StatisticsInfo.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/ProjectService.java
  COMMAND
    ${THRIFT_EXECUTABLE} --gen cpp --gen js --gen java
      -o ${CMAKE_CURRENT_BINARY_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/common.thrift
  COMMAND  
    ${THRIFT_EXECUTABLE} --gen cpp --gen js --gen java
      -o ${CMAKE_CURRENT_BINARY_DIR}
      ${CMAKE_CURRENT_SOURCE_DIR}/project.thrift
  DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/common.thrift
    ${CMAKE_CURRENT_SOURCE_DIR}/project.thrift
  COMMENT
    "Generating Thrift files for common.thrift and project.thrift")

add_library(commonthrift STATIC
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/common_types.cpp)

target_compile_options(commonthrift PUBLIC -fPIC)

add_library(projectthrift STATIC
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/project_types.cpp
  ${CMAKE_CURRENT_BINARY_DIR}/gen-cpp/ProjectService.cpp)

target_compile_options(projectthrift PUBLIC -fPIC)

add_dependencies(projectthrift commonthrift)

set(CMAKE_JAVA_INCLUDE_PATH ${PROJECT_SOURCE_DIR}/lib/java/*)

add_jar(corethriftjava
  # 来自 common.thrift 的 Java 文件
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Description.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FilePosition.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileRange.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/InvalidId.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/InvalidInput.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Position.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Range.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Timeout.java
  # 来自 project.thrift 的 Java 文件
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileParseStatus.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileInfo.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/MessageType.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/BuildLog.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/StatisticsInfo.java
  ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/ProjectService.java
  OUTPUT_NAME corethrift)

# 确保 Java 文件在 JAR 构建前生成
add_custom_target(generate_java_thrift
  DEPENDS 
    # 来自 common.thrift 的 Java 文件
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Description.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FilePosition.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileRange.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/InvalidId.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/InvalidInput.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Position.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Range.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/Timeout.java
    # 来自 project.thrift 的 Java 文件
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileParseStatus.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/FileInfo.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/MessageType.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/BuildLog.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/StatisticsInfo.java
    ${CMAKE_CURRENT_BINARY_DIR}/gen-java/cc/service/core/ProjectService.java)
add_dependencies(corethriftjava generate_java_thrift)

add_library(projectservice SHARED
  src/projectservice.cpp
  src/plugin.cpp)

target_link_libraries(projectservice
  util
  model
  ${THRIFT_LIBTHRIFT_LIBRARIES}
  projectthrift
  commonthrift)

install(TARGETS projectservice DESTINATION ${INSTALL_SERVICE_DIR})
install_jar(corethriftjava "${INSTALL_JAVA_LIB_DIR}")
install_js_thrift()
