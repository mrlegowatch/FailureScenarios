#pragma once
#include <cstddef>
#include <vector>

class DelayLineFactory {
public:
    using Handle = std::size_t;
    static constexpr Handle      kInvalidHandle = static_cast<Handle>(-1);
    static constexpr std::size_t kPoolSize      = 8;
    static constexpr std::size_t kBufferLength  = 4096;

    // Returns the module-scope static instance defined in DelayLineFactory.cpp.
    static DelayLineFactory& shared();

    DelayLineFactory();
    ~DelayLineFactory();

    // Returns a handle to an available buffer, or kInvalidHandle if the pool is exhausted.
    Handle borrow();

    // Accesses the buffer associated with a borrowed handle.
    std::vector<float>& buffer(Handle h);

    // Returns a buffer to the pool.
    void release(Handle h);

private:
    std::vector<std::vector<float>> pool_;
    std::vector<bool>               inUse_;
};

// Free-function interface to the module-scope static instance in DelayLineFactory.cpp.
namespace delay_line_factory {
    DelayLineFactory::Handle borrow();
    std::vector<float>&      buffer(DelayLineFactory::Handle h);
    void                     release(DelayLineFactory::Handle h);
}
