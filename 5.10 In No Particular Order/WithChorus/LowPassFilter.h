#pragma once
#include <cstddef>

// One-pole IIR low-pass filter: y[n] = a0*x[n] + b1*y[n-1]
class LowPassFilter {
public:
    explicit LowPassFilter(float cutoffHz = 1000.0f, float sampleRate = 44100.0f);

    void setCutoff(float cutoffHz, float sampleRate = 44100.0f);
    void process(float* samples, std::size_t count);
    void reset();

private:
    float a0_, b1_;  // feed-forward and feed-back coefficients
    float z1_;       // one-sample delay state
};
