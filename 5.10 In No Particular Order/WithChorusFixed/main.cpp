#include "OutputChain.h"
#include "Reverb.h"
#include "InitLog.h"
#include <cmath>
#include <cstdio>
#include <vector>

static constexpr std::size_t kFrames = 4096;

static std::vector<float> makeImpulse() {
    std::vector<float> buf(kFrames, 0.0f);
    buf[0] = 1.0f;
    return buf;
}

static void printStats(const char* label, const std::vector<float>& buf) {
    float peak   = 0.0f;
    float energy = 0.0f;
    for (float s : buf) {
        float a = std::fabs(s);
        if (a > peak) peak = a;
        energy += s * s;
    }
    float rms = std::sqrt(energy / static_cast<float>(kFrames));

    std::printf("%s (%zu samples)\n", label, kFrames);
    std::printf("  peak   : %.6f\n", peak);
    std::printf("  energy : %.6f\n", energy);
    std::printf("  RMS    : %.6f\n", rms);
    std::printf("  t=%4zu (dry)  : %9.6f  (expected  0.700000)\n", std::size_t(0),    buf[0]);
    std::printf("  t=%4zu (tap1) : %9.6f  (expected  0.075000)\n", std::size_t(1013), buf[1013]);
    std::printf("  t=%4zu (tap2) : %9.6f  (expected  0.075000)\n", std::size_t(1327), buf[1327]);
    std::printf("  t=%4zu (tap3) : %9.6f  (expected  0.075000)\n", std::size_t(1637), buf[1637]);
    std::printf("  t=%4zu (tap4) : %9.6f  (expected  0.075000)\n", std::size_t(2053), buf[2053]);
    std::printf("\n");
}

int main() {
    logInit("=== main() started ===");

    // Test 1: standalone Reverb constructed on the stack.
    {
        auto buf = makeImpulse();
        Reverb reverb;
        reverb.process(buf.data(), kFrames);
        printStats("Standalone Reverb — impulse response", buf);
    }  // reverb destroyed here — Delay destructors call release()

    // Test 2: the application-wide static OutputChain (gDefaultOutputChain).
    {
        auto buf = makeImpulse();
        OutputChain::shared().process(buf.data(), kFrames);
        printStats("gDefaultOutputChain — impulse response", buf);
    }

    logInit("=== main() returning ===");
    return 0;
}
