# =============================================================================
# INTENTIONAL LINKER-ERROR SCENARIO — stale object file with C/C++ mismatch
#
# readiness.o in this directory is a PRE-BUILT, CHECKED-IN artifact.
# It was compiled from readiness.cpp at a time when readiness.hpp wrapped
# the compute_readiness declaration in:
#
#     extern "C" { ... }
#
# That wrapper forced C linkage, so readiness.o exports the unmangled symbol:
#
#     _compute_readiness
#
# The extern "C" wrapper was subsequently removed from readiness.hpp.
# main.cpp now includes the updated header, sees compute_readiness as a
# plain C++ function, and the compiler emits a reference to the
# C++-mangled name (e.g. __Z17compute_readinessddddddP15ReadinessResult).
#
# The Makefile deliberately does NOT recompile readiness.cpp; it reuses
# the stale readiness.o so the symbol mismatch is permanent and
# deterministic.  Every `make` run from a clean checkout fails at the
# link step with an undefined-symbol error — no transient or
# order-dependent behaviour.
#
# This reproduces a failure that arises in practice when a pre-built
# library was compiled with extern "C" but a newer header dropped that
# wrapper (or vice versa), and the library object was never rebuilt to
# match the updated declaration.
# =============================================================================

CXX      = clang++
CXXFLAGS = -g -Wall -Wextra -std=c++20

BUILD_DIR = build
TARGET    = $(BUILD_DIR)/ReadinessScore

# Pre-built checked-in artifact — there is intentionally no rule to rebuild this.
STALE_OBJ = readiness.o
MAIN_OBJ  = $(BUILD_DIR)/main.o

.PHONY: all clean stale

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# main.cpp is compiled fresh from the current source on every clean build.
$(MAIN_OBJ): main.cpp readiness.hpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Linking against the stale readiness.o always fails: the object exports
# _compute_readiness (C linkage) but main.o references the mangled C++ name.
$(TARGET): $(MAIN_OBJ) $(STALE_OBJ)
	$(CXX) -o $@ $^

clean:
	rm -rf $(BUILD_DIR)

# stale: recreates the checked-in readiness.o for this machine, the way it was first built,
# when readiness.hpp still wrapped its declarations in extern "C" { ... }. The checked-in
# copy is a macOS (Mach-O) object; on Linux or Windows, run `make stale` once before `make`.
# The wrapper header is included ahead of readiness.cpp, so compute_readiness keeps the C
# linkage it was first declared with.
stale:
	printf 'extern "C" {\n#include "readiness.hpp"\n}\n' > stale-extern-c.h
	$(CXX) $(CXXFLAGS) -include stale-extern-c.h -c -o $(STALE_OBJ) readiness.cpp
	rm -f stale-extern-c.h
