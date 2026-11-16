#include "LowPassFilter.h"
#include "FilterRegistry.h"
#include <cmath>

static constexpr float kTwoPi = 6.28318530718f;

LowPassFilter::LowPassFilter(float cutoffHz, float sampleRate)
    : a0_(0.0f), b1_(0.0f), z1_(0.0f)
{
    setCutoff(cutoffHz, sampleRate);
}

void LowPassFilter::setCutoff(float cutoffHz, float sampleRate) {
    b1_ = std::exp(-kTwoPi * cutoffHz / sampleRate);
    a0_ = 1.0f - b1_;
}

void LowPassFilter::process(float* samples, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i) {
        z1_ = a0_ * samples[i] + b1_ * z1_;
        samples[i] = z1_;
    }
}

void LowPassFilter::reset() {
    z1_ = 0.0f;
}

// Registers "LowPassFilter" with the shared FilterRegistry at static-init time.
struct LowPassFilterRegistrar {
    LowPassFilterRegistrar() { FilterRegistry::shared().registerFilter("LowPassFilter"); }
};
static LowPassFilterRegistrar gRegistrar;
