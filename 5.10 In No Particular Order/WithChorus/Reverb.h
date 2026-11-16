#pragma once
#include "Delay.h"
#include <cstddef>

// Parallel-tap reverb composed of four internal Delay lines.
// Does not interact with DelayLineFactory directly.
class Reverb {
public:
    Reverb();

    void process(float* samples, std::size_t count);
    void reset();

private:
    Delay tap1_;   //  ~23 ms at 44.1 kHz
    Delay tap2_;   //  ~30 ms
    Delay tap3_;   //  ~37 ms
    Delay tap4_;   //  ~47 ms
};
