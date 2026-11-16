#pragma once
#include <cstddef>

class Gain {
public:
    explicit Gain(float gainDb = 0.0f);

    void setGain(float gainDb);
    void process(float* samples, std::size_t count);

private:
    float linear_;  // linear amplitude multiplier derived from gainDb
};
