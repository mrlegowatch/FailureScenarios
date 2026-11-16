#include "Reverb.h"
#include "FilterRegistry.h"

// Tap lengths in samples (incommensurate primes for dense, non-periodic decay).
static constexpr std::size_t kTap1 = 1013;
static constexpr std::size_t kTap2 = 1327;
static constexpr std::size_t kTap3 = 1637;
static constexpr std::size_t kTap4 = 2053;

Reverb::Reverb()
    : tap1_(kTap1)
    , tap2_(kTap2)
    , tap3_(kTap3)
    , tap4_(kTap4)
{}

void Reverb::process(float* samples, std::size_t count) {
    static constexpr float kDry = 0.70f;
    static constexpr float kWet = 0.075f;  // 0.30 / 4 taps
    for (std::size_t i = 0; i < count; ++i) {
        float dry = samples[i];
        float wet = tap1_.tick(dry)
                  + tap2_.tick(dry)
                  + tap3_.tick(dry)
                  + tap4_.tick(dry);
        samples[i] = kDry * dry + kWet * wet;
    }
}

void Reverb::reset() {
    tap1_.reset();
    tap2_.reset();
    tap3_.reset();
    tap4_.reset();
}

struct ReverbRegistrar {
    ReverbRegistrar() { FilterRegistry::shared().registerFilter("Reverb"); }
};
static ReverbRegistrar gRegistrar;
