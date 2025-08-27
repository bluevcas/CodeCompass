/*
 * @file odb_compatibility.h
 * @brief ODB 兼容性修复 - 解决 C++17 中 std::auto_ptr 被移除的问题
 * @details 为 ODB 库提供 std::auto_ptr 的兼容性实现，以支持现代 C++ 标准
 */

#ifndef ODB_COMPATIBILITY_H
#define ODB_COMPATIBILITY_H

#include <memory>

// 启用废弃的 auto_ptr 支持
#ifndef _GLIBCXX_USE_DEPRECATED
#define _GLIBCXX_USE_DEPRECATED 1
#endif

#ifndef _LIBCPP_ENABLE_CXX17_REMOVED_AUTO_PTR
#define _LIBCPP_ENABLE_CXX17_REMOVED_AUTO_PTR 1
#endif

// 对于 MSVC，启用废弃功能警告抑制
#ifdef _MSC_VER
#define _SILENCE_CXX17_AUTO_PTR_DEPRECATION_WARNING
#pragma warning(push)
#pragma warning(disable: 4996) // 'std::auto_ptr': 废弃警告
#endif

// 只有在确实没有 auto_ptr 定义时才需要这个修复
// MSVC 通常仍然提供这些废弃的类型
#if defined(__GNUC__) && (__cplusplus >= 201703L) && !defined(_GLIBCXX_USE_DEPRECATED)

namespace std {
    // 为 ODB 库提供 auto_ptr 的兼容性实现
    // 注意：这只是为了编译兼容性，实际使用应该迁移到 unique_ptr 或 shared_ptr
    template<typename T>
    struct auto_ptr_ref {
        T* ptr_;
        explicit auto_ptr_ref(T* p) : ptr_(p) {}
    };
    
    template<typename T>
    class auto_ptr {
    public:
        typedef T element_type;
        
        explicit auto_ptr(T* ptr = nullptr) : ptr_(ptr) {}
        
        auto_ptr(auto_ptr& other) : ptr_(other.release()) {}
        
        template<typename U>
        auto_ptr(auto_ptr<U>& other) : ptr_(other.release()) {}
        
        auto_ptr(auto_ptr_ref<T> ref) : ptr_(ref.ptr_) {}
        
        auto_ptr& operator=(auto_ptr& other) {
            if (this != &other) {
                delete ptr_;
                ptr_ = other.release();
            }
            return *this;
        }
        
        template<typename U>
        auto_ptr& operator=(auto_ptr<U>& other) {
            if (this != &other) {
                delete ptr_;
                ptr_ = other.release();
            }
            return *this;
        }
        
        auto_ptr& operator=(auto_ptr_ref<T> ref) {
            if (ref.ptr_ != ptr_) {
                delete ptr_;
                ptr_ = ref.ptr_;
            }
            return *this;
        }
        
        template<typename U>
        operator auto_ptr_ref<U>() {
            return auto_ptr_ref<U>(this->release());
        }
        
        template<typename U>
        operator auto_ptr<U>() {
            return auto_ptr<U>(this->release());
        }
        
        ~auto_ptr() {
            delete ptr_;
        }
        
        T& operator*() const {
            return *ptr_;
        }
        
        T* operator->() const {
            return ptr_;
        }
        
        T* get() const {
            return ptr_;
        }
        
        T* release() {
            T* tmp = ptr_;
            ptr_ = nullptr;
            return tmp;
        }
        
        void reset(T* ptr = nullptr) {
            if (ptr != ptr_) {
                delete ptr_;
                ptr_ = ptr;
            }
        }
        
    private:
        T* ptr_;
    };
}

#endif // 只有 GCC 需要自定义 auto_ptr

// 恢复 MSVC 警告状态
#ifdef _MSC_VER
#pragma warning(pop)
#endif

#endif // ODB_COMPATIBILITY_H
