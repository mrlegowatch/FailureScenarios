CXX      := c++
CXXFLAGS := -std=c++20 -Wall -Wextra -g
TARGET   := AudioFilters
ORDER    ?= safe
BUILD    := build/$(ORDER)

# safe: DelayLineFactory constructed before OutputChain.
SRCS_SAFE   := InitLog main DelayLineFactory FilterRegistry Gain LowPassFilter Delay Reverb OutputChain Chorus
# unsafe: OutputChain before DelayLineFactory; crashes during static construction.
SRCS_UNSAFE := InitLog main OutputChain DelayLineFactory FilterRegistry Gain LowPassFilter Delay Reverb Chorus

ifeq ($(ORDER),unsafe)
SRCS := $(SRCS_UNSAFE)
else ifeq ($(ORDER),safe)
SRCS := $(SRCS_SAFE)
else
$(error ORDER must be safe or unsafe)
endif

OBJS := $(addprefix $(BUILD)/,$(addsuffix .o,$(SRCS)))

.PHONY: all clean
all: $(BUILD)/$(TARGET)

$(BUILD)/$(TARGET): $(OBJS)
	$(CXX) $(CXXFLAGS) -o $@ $^

$(BUILD)/%.o: %.cpp %.h | $(BUILD)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD)/main.o: main.cpp | $(BUILD)
	$(CXX) $(CXXFLAGS) -c -o $@ $<

$(BUILD):
	mkdir -p $@

clean:
	rm -rf build
