#include "FilterRegistry.h"
#include <algorithm>

void FilterRegistry::registerFilter(const std::string& name) {
    entries_.push_back(name);
}

bool FilterRegistry::contains(const std::string& name) const {
    return std::find(entries_.begin(), entries_.end(), name) != entries_.end();
}

const std::vector<std::string>& FilterRegistry::names() const {
    return entries_;
}

static FilterRegistry gRegistry;

FilterRegistry& FilterRegistry::shared() { return gRegistry; }

namespace filter_registry {
    void                            registerFilter(const std::string& name) { gRegistry.registerFilter(name); }
    bool                            contains(const std::string& name)       { return gRegistry.contains(name); }
    const std::vector<std::string>& names()                                 { return gRegistry.names(); }
}
