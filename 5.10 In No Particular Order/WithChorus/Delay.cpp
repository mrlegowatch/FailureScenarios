#include "Delay.h"
#include "DelayLineFactory.h"
#include "FilterRegistry.h"
#include "InitLog.h"
#include <algorithm>

Delay::Delay(std::size_t delaySamples)
    : handle_(DelayLineFactory::shared().borrow())
    , delaySamples_(delaySamples)
    , writePos_(0)
{}

Delay::~Delay() {
    DelayLineFactory::shared().release(handle_);
}

float Delay::tick(float input) {
    auto& buf = DelayLineFactory::shared().buffer(handle_);
    std::size_t readPos = (writePos_ + DelayLineFactory::kBufferLength - delaySamples_)
                          % DelayLineFactory::kBufferLength;
    float out = buf[readPos];
    buf[writePos_] = input;
    writePos_ = (writePos_ + 1) % DelayLineFactory::kBufferLength;
    return out;
}

void Delay::process(float* samples, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i)
        samples[i] = tick(samples[i]);
}

void Delay::reset() {
    auto& buf = DelayLineFactory::shared().buffer(handle_);
    std::fill(buf.begin(), buf.end(), 0.0f);
    writePos_ = 0;
}

struct DelayRegistrar {
    DelayRegistrar()  { FilterRegistry::shared().registerFilter("Delay");
                        logInit("DelayRegistrar   constructed  (registered \"Delay\")"); }
    ~DelayRegistrar() { logInit("DelayRegistrar   DESTROYED"); }
};
static DelayRegistrar gRegistrar;
