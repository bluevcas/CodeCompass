cmake_minimum_required(VERSION 3.16.3)

# ================ vcpkg 配置 ================
# 设置 vcpkg 工具链文件
set(VCPKG_ROOT "D:/APPLICATIONS/vcpkg")
set(CMAKE_TOOLCHAIN_FILE "${VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
    CACHE STRING "Vcpkg toolchain file")

# 强制设置 vcpkg triplet 为动态版本
set(VCPKG_TARGET_TRIPLET "x64-windows")
set(ENV{VCPKG_DEFAULT_TRIPLET} "x64-windows")

# 完全禁用系统路径搜索，避免与其他库冲突
set(CMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH OFF)
set(CMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH OFF)
set(CMAKE_FIND_USE_CMAKE_SYSTEM_PATH OFF)

# 设置 CMAKE 策略以优先使用 vcpkg
set(CMAKE_FIND_PACKAGE_PREFER_CONFIG TRUE)

# 为 LLVM 单独设置搜索路径
list(APPEND CMAKE_PREFIX_PATH "${VCPKG_ROOT}/installed/x64-windows")
list(APPEND CMAKE_PREFIX_PATH "${VCPKG_ROOT}/installed/x64-windows-release-rtti")

project(CodeCompass)

# ================ 编译器和运行时库配置 ================
# 全局设置
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# 强制使用动态库（参考 AvaSense）
set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)

# 强制使用动态运行时库以匹配vcpkg依赖项
if(MSVC)
    set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")
    # 移除任何现有的/MT标志并替换为/MD
    string(REPLACE "/MT" "/MD" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")
    string(REPLACE "/MTd" "/MDd" CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}")
    
    # 清空 CMAKE_CXX_FLAGS 以避免继承任何默认的 GCC 标志
    set(CMAKE_CXX_FLAGS "")
    set(CMAKE_C_FLAGS "")
    
    # 强制所有编译选项都使用动态运行时库
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /MD")
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /MD")
    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /MD")
    set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} /MD")
    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /MDd") 
    set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} /MDd")
endif()

# Common config variables and settings
include(Config.cmake)

# Utility functions
include(Functions.cmake)

# Do some sanity check on the testing setup and enable testing if applicable.
include(Testing.cmake)

# ================ 依赖库配置（使用 vcpkg） ================

# 使用 vcpkg 查找 Boost 库
find_package(Boost CONFIG REQUIRED COMPONENTS 
    filesystem 
    system 
    thread 
    log 
    program_options 
    regex 
    date_time 
    exception
)

# ================ Java 配置（用于搜索功能） ================
# 检查是否需要 Java 功能
option(ENABLE_JAVA_SEARCH "启用 Java 搜索功能（需要 JDK）" ON)

if(ENABLE_JAVA_SEARCH)
    # 手动设置 Java 路径，避免环境变量问题
    set(JAVA_HOME "D:/APPLICATIONS/jdk-17.0.2")
    set(Java_JAVA_EXECUTABLE "${JAVA_HOME}/bin/java.exe")
    set(Java_JAVAC_EXECUTABLE "${JAVA_HOME}/bin/javac.exe")
    set(Java_JAR_EXECUTABLE "${JAVA_HOME}/bin/jar.exe")
    set(Java_JAVADOC_EXECUTABLE "${JAVA_HOME}/bin/javadoc.exe")
    # 注意：javah 在 Java 9+ 中已移除，使用 javac -h 替代
    
    # 验证 Java 可执行文件是否存在
    if(EXISTS "${Java_JAVA_EXECUTABLE}" AND EXISTS "${Java_JAVAC_EXECUTABLE}")
        find_package(Java REQUIRED)
        if(Java_FOUND)
            message(STATUS "找到 Java: ${Java_VERSION} (路径: ${JAVA_HOME})")
            set(JAVA_AVAILABLE TRUE)
        else()
            message(WARNING "Java 验证失败，搜索功能将被禁用")
            set(JAVA_AVAILABLE FALSE)
        endif()
    else()
        message(WARNING "未找到 Java 可执行文件，搜索功能将被禁用")
        message(STATUS "  期望路径: ${Java_JAVA_EXECUTABLE}")
        set(JAVA_AVAILABLE FALSE)
    endif()
else()
    message(STATUS "Java 搜索功能已禁用（可通过 -DENABLE_JAVA_SEARCH=ON 启用）")
    set(JAVA_AVAILABLE FALSE)
endif()

# ================ LLVM/Clang 配置（C++ 解析需要） ================
# 检查 vcpkg 是否安装了 LLVM
if(EXISTS "${VCPKG_ROOT}/installed/x64-windows/lib/LLVMCore.lib" OR 
   EXISTS "${VCPKG_ROOT}/installed/x64-windows-release-rtti/lib/LLVMCore.lib")
    
    # 尝试使用 vcpkg 安装的 LLVM
    find_package(LLVM CONFIG)
    if(LLVM_FOUND)
        message(STATUS "找到 vcpkg LLVM: ${LLVM_PACKAGE_VERSION}")
        set(LLVM_AVAILABLE TRUE)
        
        # 配置 LLVM CMake 模块路径和选项
        list(APPEND CMAKE_MODULE_PATH "${LLVM_CMAKE_DIR}")
        include(HandleLLVMOptions)
        add_definitions(${LLVM_DEFINITIONS})
        
        # 查找 Clang
        find_package(Clang CONFIG)
        if(Clang_FOUND)
            message(STATUS "找到 vcpkg Clang")
            set(CLANG_AVAILABLE TRUE)
        else()
            message(WARNING "未找到 Clang，C++ 解析功能可能受限")
            set(CLANG_AVAILABLE FALSE)
        endif()
    else()
        message(WARNING "未找到 LLVM CONFIG 文件")
        set(LLVM_AVAILABLE FALSE)
        set(CLANG_AVAILABLE FALSE)
    endif()
else()
    message(WARNING "vcpkg 中未安装 LLVM，请运行:")
    message(WARNING "  vcpkg install llvm[tools,clang-tools-extra]:x64-windows")
    message(WARNING "  或者")
    message(WARNING "  vcpkg install llvm[tools,clang-tools-extra]:x64-windows-release-rtti")
    set(LLVM_AVAILABLE FALSE)
    set(CLANG_AVAILABLE FALSE)
endif()

# 线程支持
find_package(Threads REQUIRED)

# OpenSSL 支持（webserver 需要）
find_package(OpenSSL REQUIRED)
if(OpenSSL_FOUND)
    message(STATUS "找到 OpenSSL: ${OPENSSL_VERSION}")
else()
    message(FATAL_ERROR "未找到 OpenSSL，请通过 vcpkg 安装: vcpkg install openssl:x64-windows")
endif()

# GTest（可选）
find_package(GTest)

# ================ ODB 配置（使用 vcpkg 安装的版本） ================
# 使用 vcpkg 安装的 ODB 库
set(ODB_FOUND TRUE)
set(ODB_INCLUDE_DIRS "${VCPKG_ROOT}/installed/x64-windows/include")
set(ODB_LIBRARY_DIRS "${VCPKG_ROOT}/installed/x64-windows/lib")

# 查找ODB库文件
find_library(ODB_LIBRARY odb HINTS ${ODB_LIBRARY_DIRS})
find_library(ODB_SQLITE_LIBRARY odb-sqlite HINTS ${ODB_LIBRARY_DIRS})

if(NOT ODB_LIBRARY OR NOT ODB_SQLITE_LIBRARY)
    message(FATAL_ERROR "未找到 vcpkg ODB 库文件")
endif()

set(ODB_LIBRARIES ${ODB_LIBRARY} ${ODB_SQLITE_LIBRARY})
set(ODB_SQLITE_LIBRARIES ${ODB_SQLITE_LIBRARY})

message(STATUS "找到 vcpkg ODB 库: ${ODB_INCLUDE_DIRS}")
message(STATUS "ODB 库文件: ${ODB_LIBRARY}")
message(STATUS "ODB SQLite 库文件: ${ODB_SQLITE_LIBRARY}")

# 查找 ODB 编译器
set(ODB_EXECUTABLE "D:/APPLICATIONS/Library/odb-2.4.0-i686-windows/bin/odb.exe")
if(EXISTS "${ODB_EXECUTABLE}")
    message(STATUS "找到 ODB 编译器: ${ODB_EXECUTABLE}")
else()
    find_program(ODB_EXECUTABLE odb)
    if(NOT ODB_EXECUTABLE)
        message(WARNING "ODB 编译器未找到，数据模型生成可能失败")
        message(STATUS "  请安装 ODB 编译器")
    else()
        message(STATUS "找到 ODB 编译器: ${ODB_EXECUTABLE}")
    endif()
endif()

# ================ Thrift 配置（使用 vcpkg） ================
# 手动设置 vcpkg 安装的 Thrift 路径
set(THRIFT_EXECUTABLE "${VCPKG_ROOT}/installed/x64-windows/tools/thrift/thrift.exe")
set(THRIFT_INCLUDE_DIR "${VCPKG_ROOT}/installed/x64-windows/include")
set(THRIFT_LIBRARY "${VCPKG_ROOT}/installed/x64-windows/lib/thriftmd.lib")

# 验证 Thrift 可执行文件是否存在
if(EXISTS "${THRIFT_EXECUTABLE}")
    message(STATUS "找到 vcpkg Thrift 编译器: ${THRIFT_EXECUTABLE}")
    set(THRIFT_FOUND TRUE)
    set(THRIFT_INCLUDE_DIRS ${THRIFT_INCLUDE_DIR})
    set(THRIFT_LIBRARIES ${THRIFT_LIBRARY})
    set(THRIFT_LIBTHRIFT_INCLUDE_DIRS ${THRIFT_INCLUDE_DIR})
    set(THRIFT_LIBTHRIFT_LIBRARIES ${THRIFT_LIBRARY})
    
    # 验证库文件是否存在
    if(EXISTS "${THRIFT_LIBRARY}")
        message(STATUS "找到 Thrift 库: ${THRIFT_LIBRARY}")
    else()
        message(WARNING "Thrift 库文件未找到: ${THRIFT_LIBRARY}")
    endif()
else()
    message(FATAL_ERROR "未找到 Thrift 编译器，请确保已通过 vcpkg 安装: vcpkg install thrift:x64-windows")
    set(THRIFT_FOUND FALSE)
endif()

# ================ 库版本信息输出 ================
message(STATUS "依赖库版本信息:")
message(STATUS "  Boost: ${Boost_VERSION}")
if(THRIFT_FOUND)
    message(STATUS "  Thrift: 已找到")
endif()
message(STATUS "  ODB: 已配置 (vcpkg 版本)")
if(JAVA_AVAILABLE)
    message(STATUS "  Java: ${Java_VERSION} (搜索功能已启用)")
else()
    message(STATUS "  Java: 未启用 (搜索功能已禁用)")
endif()
if(OpenSSL_FOUND)
    message(STATUS "  OpenSSL: ${OPENSSL_VERSION} (webserver 功能已启用)")
endif()

# 只在 Java 可用时包含 UseJava
if(JAVA_AVAILABLE)
    include(UseJava)
    set(CMAKE_JAVA_COMPILE_FLAGS -encoding utf8)
endif()

# Set the third-party libraries' path properly so the installation can find them.
include(Exports.cmake)
set(CMAKE_INSTALL_RPATH "${CMAKE_INSTALL_RPATH};${RUNENV_LD_LIBRARY_PATH}")

# Modules
add_subdirectory(logger)
add_subdirectory(model)
add_subdirectory(parser)
add_subdirectory(scripts)
add_subdirectory(service)
add_subdirectory(util)
add_subdirectory(plugins) # must precede webgui
add_subdirectory(webgui)
add_subdirectory(webgui-new)
add_subdirectory(webserver)

# Install java libraries
install(DIRECTORY
  lib/java/
  DESTINATION "${INSTALL_JAVA_LIB_DIR}")
