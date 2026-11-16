#include "DelayLineFactory.h"
#include "InitLog.h"

DelayLineFactory::DelayLineFactory()
    : pool_(kPoolSize, std::vector<float>(kBufferLength, 0.0f))
    , inUse_(kPoolSize, false)
{
    logInit("gFactory         constructed  (pool=%zu buffers)", kPoolSize);
}

DelayLineFactory::~DelayLineFactory() {
    logInit("gFactory         DESTROYED");
}

DelayLineFactory::Handle DelayLineFactory::borrow() {
    logInit("borrow()         called  inUse_.size()=%zu", inUse_.size());
    for (std::size_t i = 0; i < kPoolSize; ++i) {
        if (!inUse_[i]) {
            inUse_[i] = true;
            return i;
        }
    }
    return kInvalidHandle;
}

std::vector<float>& DelayLineFactory::buffer(Handle h) {
    return pool_[h];
}

void DelayLineFactory::release(Handle h) {
    logInit("release()        handle=%zu", h);
    if (h < kPoolSize)
        inUse_[h] = false;
}

// Construct-On-First-Use: the function-local static is guaranteed by C++11
// to be initialized the first time this function is called, regardless of
// link order, and destroyed only after all objects that called shared()
// during their own construction have been destroyed.  This eliminates the
// static-initialization-order fiasco that the namespace-scope gFactory had.
DelayLineFactory& DelayLineFactory::shared() {
    static DelayLineFactory instance;
    return instance;
}

namespace delay_line_factory {
    DelayLineFactory::Handle borrow()                           { return DelayLineFactory::shared().borrow(); }
    std::vector<float>&      buffer(DelayLineFactory::Handle h) { return DelayLineFactory::shared().buffer(h); }
    void                     release(DelayLineFactory::Handle h){ DelayLineFactory::shared().release(h); }
}
