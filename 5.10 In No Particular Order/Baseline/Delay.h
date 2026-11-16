#pragma once
#include <cstddef>

class Delay {
public:
    explicit Delay(std::size_t delaySamples);
    ~Delay();

    Delay(const Delay&)            = delete;
    Delay& operator=(const Delay&) = delete;

    // Process one sample, returning the delayed output.
    float tick(float input);

    // In-place block processing.
    void process(float* samples, std::size_t count);

    void reset();

private:
    std::size_t handle_;        // index into DelayLineFactory pool
    std::size_t delaySamples_;
    std::size_t writePos_;
};
