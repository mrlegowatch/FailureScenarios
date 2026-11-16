# =============================================================================
# FIX for the LinkerError scenario (C/C++ symbol mismatch)
#
# The original LinkerError/ directory used a pre-built, checked-in
# readiness.o that was compiled when readiness.hpp still had an
# extern "C" { ... } wrapper around compute_readiness.  That gave the
# object C linkage (_compute_readiness, unmangled), while the updated
# header caused main.cpp to expect the C++-mangled name — a mismatch
# the linker could not resolve.
#
# The fix is to build readiness.o from the current source alongside
# every other translation unit so that all objects agree on linkage.
# There is no stale artifact; make tracks dependencies normally.
# =============================================================================

CXX      = clang++
# -ftrivial-auto-var-init=uninitialized keeps uninitialized locals uninitialized, as the case
# depends on, even if a future compiler starts filling them by default.
CXXFLAGS = -g -Wall -Wextra -std=c++20 -ftrivial-auto-var-init=uninitialized

BUILD_DIR = build
TARGET    = $(BUILD_DIR)/ReadinessScore

OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/readiness.o

.PHONY: all clean

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.cpp readiness.hpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(TARGET): $(OBJS)
	$(CXX) -o $@ $^

clean:
	rm -rf $(BUILD_DIR)
