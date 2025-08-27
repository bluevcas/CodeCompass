add_subdirectory(authenticators)

# 查找 OpenSSL
find_package(OpenSSL REQUIRED)

add_executable(CodeCompass_webserver
  src/webserver.cpp
  src/authentication.cpp
  src/mainrequesthandler.cpp
  src/session.cpp
  src/sessionmanager.cpp
  src/threadedmongoose.cpp)

set_target_properties(CodeCompass_webserver
  PROPERTIES ENABLE_EXPORTS 1)

add_library(mongoose STATIC src/mongoose.c )
target_compile_definitions(mongoose PRIVATE -DNS_ENABLE_SSL)
target_include_directories(mongoose PUBLIC 
  include
  # 添加 OpenSSL 包含路径
  ${OPENSSL_INCLUDE_DIR}
)
# 根据编译器类型设置适当的编译选项
if(MSVC)
  target_compile_options(mongoose PUBLIC /EHsc)
else()
  target_compile_options(mongoose PUBLIC -fPIC)
endif()
# 正确链接 vcpkg 安装的 OpenSSL 库
target_link_libraries(mongoose PRIVATE 
  OpenSSL::SSL 
  OpenSSL::Crypto
)

target_include_directories(CodeCompass_webserver PUBLIC
  include
  ${PROJECT_SOURCE_DIR}/model/include
  ${PROJECT_SOURCE_DIR}/util/include)

target_link_libraries(CodeCompass_webserver
  util
  mongoose
  ${Boost_LIBRARIES}
  ${ODB_LIBRARIES}
  pthread
  dl)

install(TARGETS CodeCompass_webserver
  RUNTIME DESTINATION ${INSTALL_BIN_DIR}
  LIBRARY DESTINATION ${INSTALL_LIB_DIR})
