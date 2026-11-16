#pragma once
#include "Delay.h"
#include <cstddef>

// Minimal sine LFO: tick() returns a value in [-1, 1].
struct LFO {
    explicit LFO(float rateHz = 0.5f, float sampleRate = 44100.0f) noexcept;
    float tick() noexcept;
    void  reset() noexcept;
private:
    float phase_;
    float increment_;
};

// Chorus: LFO-modulated wet mix over a fixed-length delay line.
// Does not interact with DelayLineFactory directly.
class Chorus {
public:
    explicit Chorus(float       lfoRateHz  = 0.5f,
                    float       depth      = 0.3f,
                    float       sampleRate = 44100.0f,
                    std::size_t baseDelay  = 800);

    void process(float* samples, std::size_t count);
    void reset();

private:
    LFO         lfo_;
    Delay       delay_;
    float       depth_;
};
