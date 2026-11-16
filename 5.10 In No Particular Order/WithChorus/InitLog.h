#pragma once
#include <cstdarg>

// Writes "[N] <message>\n" to stderr, where N is a global sequence counter.
// Safe to call from any static constructor or destructor.
void logInit(const char* fmt, ...);
