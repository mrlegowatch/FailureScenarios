//
//  main.cpp
//  Baseline
//
//  Created by Brian Arnold on 7/1/26.
//

#include <algorithm>
#include <cctype>
#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include <dirent.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

// Plausible Unix epoch bounds: 0 through ~year 3000
static constexpr long long kTimestampMin = 0LL;
static constexpr long long kTimestampMax = 32503680000LL;

// Plausible sensor value range
static constexpr double kValueMin = -100.0;
static constexpr double kValueMax = 10000.0;

static std::string trim(const std::string& s) {
    const char* ws = " \t\r\n";
    size_t first = s.find_first_not_of(ws);
    if (first == std::string::npos) return {};
    size_t last = s.find_last_not_of(ws);
    return s.substr(first, last - first + 1);
}

static std::vector<std::string> splitCSVRow(const std::string& line) {
    std::vector<std::string> fields;
    std::istringstream ss(line);
    std::string field;
    while (std::getline(ss, field, ',')) {
        fields.push_back(trim(field));
    }
    return fields;
}

static bool validateTimestamp(const std::string& s, std::string& reason) {
    if (s.empty()) {
        reason = "empty";
        return false;
    }
    char* end;
    errno = 0;
    long long ts = std::strtoll(s.c_str(), &end, 10);
    if (end == s.c_str() || *end != '\0') {
        reason = "not a valid integer";
        return false;
    }
    if (errno == ERANGE) {
        reason = "overflows 64-bit integer";
        return false;
    }
    if (ts < kTimestampMin || ts > kTimestampMax) {
        reason = "not a plausible Unix epoch (expected 0-32503680000)";
        return false;
    }
    return true;
}

static bool validateSensorID(const std::string& s, std::string& reason) {
    if (s.empty()) {
        reason = "empty";
        return false;
    }
    for (unsigned char c : s) {
        if (!std::isalnum(c)) {
            reason = "contains non-alphanumeric character";
            return false;
        }
    }
    return true;
}

static bool validateValue(const std::string& s, std::string& reason) {
    if (s.empty()) {
        reason = "empty";
        return false;
    }
    char* end;
    errno = 0;
    double v = std::strtod(s.c_str(), &end);
    if (end == s.c_str() || *end != '\0') {
        reason = "not a valid number";
        return false;
    }
    if (errno == ERANGE) {
        reason = "overflows double";
        return false;
    }
    if (v < kValueMin || v > kValueMax) {
        reason = "outside plausible sensor range [-100, 10000]";
        return false;
    }
    return true;
}

static int runWorker() {
    std::cerr << "worker PID " << getpid() << " starting\n";

    int rowCount = 0;
    int errorCount = 0;
    std::string line;

    while (std::getline(std::cin, line)) {
        if (!line.empty() && line.back() == '\r') line.pop_back();
        if (line.empty()) continue;

        ++rowCount;
        const auto fields = splitCSVRow(line);

        if (fields.size() != 4) {
            std::cout << "row " << rowCount
                      << ": row invalid: expected 4 fields, got " << fields.size() << "\n";
            ++errorCount;
            continue;
        }

        std::string reason;

        if (!validateTimestamp(fields[0], reason)) {
            std::cout << "row " << rowCount << ": timestamp invalid: " << reason << "\n";
            ++errorCount;
        }
        if (!validateSensorID(fields[1], reason)) {
            std::cout << "row " << rowCount << ": sensorID invalid: " << reason << "\n";
            ++errorCount;
        }
        if (!validateValue(fields[2], reason)) {
            std::cout << "row " << rowCount << ": value invalid: " << reason << "\n";
            ++errorCount;
        }
    }

    std::cout << "validated " << rowCount << " rows, " << errorCount << " errors\n";
    return errorCount > 0 ? 1 : 0;
}

// With no argument, read the Fixtures folder next to this program's source folder, so it
// runs from Xcode or swift run with nothing to configure.
static std::string defaultFixturesDir() {
    std::string path = __FILE__;
    for (int i = 0; i < 2; ++i) {   // drop the file name, then its folder
        const auto slash = path.find_last_of('/');
        path = slash == std::string::npos ? "." : path.substr(0, slash);
    }
    return path + "/Fixtures";
}

static int runParent(int argc, char* argv[]) {
    const std::string dir = argc > 1 ? argv[1] : defaultFixturesDir();

    // Collect .csv files, sorted for deterministic run order.
    std::vector<std::string> filenames;
    DIR* dp = opendir(dir.c_str());
    if (!dp) {
        std::cerr << argv[0] << ": cannot open directory: " << dir << "\n";
        return 1;
    }
    struct dirent* entry;
    while ((entry = readdir(dp)) != nullptr) {
        const std::string name = entry->d_name;
        if (name.size() > 4 && name.compare(name.size() - 4, 4, ".csv") == 0) {
            filenames.push_back(name);
        }
    }
    closedir(dp);
    std::sort(filenames.begin(), filenames.end());

    struct ChildInfo {
        pid_t pid;
        int stdoutReadFd;
        std::string filename;
    };
    std::vector<ChildInfo> children;

    // workerArgv is shared across iterations; fork copies are independent.
    char workerFlag[] = "--worker";
    char* workerArgv[] = { argv[0], workerFlag, nullptr };

    for (const auto& filename : filenames) {
        const std::string path = dir + "/" + filename;

        std::ifstream f(path, std::ios::binary);
        if (!f) {
            std::cerr << argv[0] << ": cannot open: " << path << "\n";
            continue;
        }
        std::ostringstream oss;
        oss << f.rdbuf();
        const std::string contents = oss.str();

        int stdinPipe[2], stdoutPipe[2];
        if (pipe(stdinPipe) != 0 || pipe(stdoutPipe) != 0) {
            std::cerr << argv[0] << ": pipe: " << std::strerror(errno) << "\n";
            return 1;
        }

        pid_t pid = fork();
        if (pid < 0) {
            std::cerr << argv[0] << ": fork: " << std::strerror(errno) << "\n";
            return 1;
        }

        if (pid == 0) {
            dup2(stdinPipe[0],  STDIN_FILENO);
            close(stdinPipe[0]);
            close(stdinPipe[1]);
            dup2(stdoutPipe[1], STDOUT_FILENO);
            close(stdoutPipe[0]);
            close(stdoutPipe[1]);
            execv(argv[0], workerArgv);
            _exit(1);
        }

        // Parent: close the child-facing ends, write file contents, then move on.
        close(stdinPipe[0]);
        close(stdoutPipe[1]);

        const char* data = contents.data();
        size_t remaining = contents.size();
        while (remaining > 0) {
            ssize_t n = write(stdinPipe[1], data, remaining);
            if (n <= 0) break;
            data += n;
            remaining -= static_cast<size_t>(n);
        }
        close(stdinPipe[1]);

        children.push_back({ pid, stdoutPipe[0], filename });
    }

    // Collect results in launch order: wait for each child, then drain its output.
    int result = 0;
    for (const auto& child : children) {
        int status = 0;
        waitpid(child.pid, &status, 0);
        if (WIFEXITED(status) && WEXITSTATUS(status) != 0) result = 1;

        std::cout << "=== " << child.filename << " ===\n";
        char buf[4096];
        ssize_t n;
        while ((n = read(child.stdoutReadFd, buf, sizeof(buf))) > 0) {
            std::cout.write(buf, n);
        }
        close(child.stdoutReadFd);
    }

    return result;
}

int main(int argc, char* argv[]) {
    if (argc > 1 && std::strcmp(argv[1], "--worker") == 0) {
        return runWorker();
    }
    return runParent(argc, argv);
}
