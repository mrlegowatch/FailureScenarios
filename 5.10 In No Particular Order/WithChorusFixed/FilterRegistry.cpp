#include "FilterRegistry.h"
#include "InitLog.h"
#include <algorithm>

FilterRegistry::FilterRegistry() {
    logInit("gRegistry        constructed");
}

FilterRegistry::~FilterRegistry() {
    logInit("gRegistry        DESTROYED");
}

void FilterRegistry::registerFilter(const std::string& name) {
    entries_.push_back(name);
}

bool FilterRegistry::contains(const std::string& name) const {
    return std::find(entries_.begin(), entries_.end(), name) != entries_.end();
}

const std::vector<std::string>& FilterRegistry::names() const {
    return entries_;
}

// Construct-On-First-Use: same guarantee as DelayLineFactory::shared().
FilterRegistry& FilterRegistry::shared() {
    static FilterRegistry instance;
    return instance;
}

namespace filter_registry {
    void                            registerFilter(const std::string& name) { FilterRegistry::shared().registerFilter(name); }
    bool                            contains(const std::string& name)       { return FilterRegistry::shared().contains(name); }
    const std::vector<std::string>& names()                                 { return FilterRegistry::shared().names(); }
}
