#include "OutputChain.h"

void OutputChain::process(float* samples, std::size_t count) {
    reverb_.process(samples, count);
}

void OutputChain::reset() {
    reverb_.reset();
}

// Re-creating this chain per sound effect would be wasteful, so the application
// keeps one shared instance alive for its entire lifetime.  Its destructor —
// and therefore its internal Reverb's destructor, and that Reverb's internal
// Delays' destructors — will run during the static-teardown phase after main()
// returns.  That lifetime is what gives the eventual destruction-order hazard
// somewhere real to live.
static OutputChain gDefaultOutputChain;

OutputChain& OutputChain::shared() { return gDefaultOutputChain; }
