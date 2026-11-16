#include "DelayLineFactory.h"

DelayLineFactory::DelayLineFactory()
    : pool_(kPoolSize, std::vector<float>(kBufferLength, 0.0f))
    , inUse_(kPoolSize, false)
{}

DelayLineFactory::Handle DelayLineFactory::borrow() {
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
    if (h < kPoolSize)
        inUse_[h] = false;
}

static DelayLineFactory gFactory;

DelayLineFactory& DelayLineFactory::shared() { return gFactory; }

namespace delay_line_factory {
    DelayLineFactory::Handle borrow()                      { return gFactory.borrow(); }
    std::vector<float>&      buffer(DelayLineFactory::Handle h) { return gFactory.buffer(h); }
    void                     release(DelayLineFactory::Handle h) { gFactory.release(h); }
}
