#pragma once
#include <string>
#include <vector>

class FilterRegistry {
public:
    // Returns the module-scope static instance defined in FilterRegistry.cpp.
    static FilterRegistry& shared();

    void                            registerFilter(const std::string& name);
    bool                            contains(const std::string& name) const;
    const std::vector<std::string>& names() const;

private:
    std::vector<std::string> entries_;
};

// Free-function interface to the module-scope static instance in FilterRegistry.cpp.
namespace filter_registry {
    void                            registerFilter(const std::string& name);
    bool                            contains(const std::string& name);
    const std::vector<std::string>& names();
}
