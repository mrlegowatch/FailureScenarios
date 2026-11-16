#include "InitLog.h"
#include <cstdarg>
#include <cstdio>

// Plain int — zero-initialized before any dynamic initialization runs, so
// logInit() is safe to call from the very first static constructor.
static int gSeq;

void logInit(const char* fmt, ...) {
    std::fprintf(stderr, "[%2d] ", ++gSeq);
    std::va_list ap;
    va_start(ap, fmt);
    std::vfprintf(stderr, fmt, ap);
    va_end(ap);
    std::fputc('\n', stderr);
    std::fflush(stderr);
}
