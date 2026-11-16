#include "Chorus.h"
#include "FilterRegistry.h"
#include "InitLog.h"
#include <cmath>

static constexpr float kTwoPi = 6.28318530718f;

LFO::LFO(float rateHz, float sampleRate) noexcept
    : phase_(0.0f)
    , increment_(kTwoPi * rateHz / sampleRate)
{}

float LFO::tick() noexcept {
    float v = std::sin(phase_);
    phase_ += increment_;
    if (phase_ >= kTwoPi) phase_ -= kTwoPi;
    return v;
}

void LFO::reset() noexcept {
    phase_ = 0.0f;
}

Chorus::Chorus(float lfoRateHz, float depth, float sampleRate, std::size_t baseDelay)
    : lfo_(lfoRateHz, sampleRate)
    , delay_(baseDelay)
    , depth_(depth)
{}

void Chorus::process(float* samples, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i) {
        float dry  = samples[i];
        float mod  = lfo_.tick();
        float wet  = delay_.tick(dry);
        samples[i] = dry + depth_ * mod * wet;
    }
}

void Chorus::reset() {
    lfo_.reset();
    delay_.reset();
}

struct ChorusRegistrar {
    ChorusRegistrar()  { FilterRegistry::shared().registerFilter("Chorus");
                         logInit("ChorusRegistrar  constructed  (registered \"Chorus\")"); }
    ~ChorusRegistrar() { logInit("ChorusRegistrar  DESTROYED"); }
};
static ChorusRegistrar gRegistrar;
