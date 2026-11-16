#include "Gain.h"
#include "FilterRegistry.h"
#include <cmath>

Gain::Gain(float gainDb)
    : linear_(std::pow(10.0f, gainDb / 20.0f))
{}

void Gain::setGain(float gainDb) {
    linear_ = std::pow(10.0f, gainDb / 20.0f);
}

void Gain::process(float* samples, std::size_t count) {
    for (std::size_t i = 0; i < count; ++i)
        samples[i] *= linear_;
}

// Registers "Gain" with the shared FilterRegistry at static-init time.
struct GainRegistrar {
    GainRegistrar() { FilterRegistry::shared().registerFilter("Gain"); }
};
static GainRegistrar gRegistrar;
