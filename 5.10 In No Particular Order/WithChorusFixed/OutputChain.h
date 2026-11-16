#pragma once
#include "Reverb.h"
#include <cstddef>

// The application-wide effects chain applied to every UI sound effect,
// giving them a consistent "house style" rather than sounding dry.
class OutputChain {
public:
    // Returns the module-scope static instance defined in OutputChain.cpp.
    static OutputChain& shared();

    OutputChain();
    ~OutputChain();
    void process(float* samples, std::size_t count);
    void reset();
private:
    Reverb reverb_;
};
