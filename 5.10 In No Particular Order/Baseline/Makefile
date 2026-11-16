CXX      := c++
CXXFLAGS := -std=c++20 -Wall -Wextra
TARGET   := AudioFilters
BUILD    := build

SRCS := main DelayLineFactory FilterRegistry Gain LowPassFilter Delay Reverb OutputChain
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
