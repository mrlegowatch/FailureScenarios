#include "OutputChain.h"
#include "InitLog.h"

OutputChain::OutputChain() {
    // Reaches here only after all Delay members inside reverb_ are constructed
    // (i.e., all borrow() calls have already succeeded).
    logInit("OutputChain      gDefaultOutputChain  constructed  (Delays borrowed)");
}

OutputChain::~OutputChain() {
    // Reaches here before any Delay members are destroyed; release() calls follow.
    logInit("OutputChain      gDefaultOutputChain  DESTROYING   (about to release Delays)");
}

void OutputChain::process(float* samples, std::size_t count) {
    reverb_.process(samples, count);
}

void OutputChain::reset() {
    reverb_.reset();
}

// Logs the moment gDefaultOutputChain's initialization is attempted — even if
// it crashes during member construction before the constructor body is reached.
static struct OutputChainInitTracer {
    OutputChainInitTracer()  { logInit("OutputChain.cpp  gDefaultOutputChain  init  STARTING"); }
    ~OutputChainInitTracer() { logInit("OutputChain.cpp  gDefaultOutputChain  fini  COMPLETE"); }
} gInitTracer;

// Re-creating this chain per sound effect would be wasteful, so the application
// keeps one shared instance alive for its entire lifetime.  Its destructor —
// and therefore its internal Reverb's destructor, and that Reverb's internal
// Delays' destructors — will run during the static-teardown phase after main()
// returns.  That lifetime is what gives the eventual destruction-order hazard
// somewhere real to live.
static OutputChain gDefaultOutputChain;

OutputChain& OutputChain::shared() { return gDefaultOutputChain; }
