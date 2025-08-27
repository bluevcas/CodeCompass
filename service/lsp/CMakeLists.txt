include_directories(include)

add_library(lspservice STATIC
  src/lspservice.cpp
  src/lsp_types.cpp)

# 根据编译器类型设置适当的编译选项
if(MSVC)
  target_compile_options(lspservice PUBLIC /EHsc)
else()
  target_compile_options(lspservice PUBLIC -fPIC)
endif()

target_link_libraries(lspservice
  ${Boost_LIBRARIES})
