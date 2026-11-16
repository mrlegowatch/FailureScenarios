CC       = clang
CXX      = clang++
CFLAGS   = -g -Wall -Wextra -std=c17
CXXFLAGS = -g -Wall -Wextra -std=c++20
LDFLAGS  =

BUILD_DIR = build
TARGET    = $(BUILD_DIR)/ReadinessScore

C_SRCS   = $(wildcard *.c)
CXX_SRCS = $(wildcard *.cpp)

C_OBJS   = $(patsubst %.c,   $(BUILD_DIR)/%.o, $(C_SRCS))
CXX_OBJS = $(patsubst %.cpp, $(BUILD_DIR)/%.o, $(CXX_SRCS))
OBJS     = $(C_OBJS) $(CXX_OBJS)

# Use clang++ as linker when any C++ objects are present
LINK = $(if $(CXX_OBJS),$(CXX),$(CC))

.PHONY: all clean nm

all: $(BUILD_DIR) $(TARGET)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(OBJS)
	$(LINK) $(LDFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c -o $@ $<

# Print symbols for every object file
nm: $(OBJS)
	@for obj in $(OBJS); do \
		echo "=== $$obj ==="; \
		nm "$$obj"; \
		echo; \
	done

clean:
	rm -rf $(BUILD_DIR)
