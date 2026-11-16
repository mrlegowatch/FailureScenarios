//
//  CapacityBoundaryTests.swift
//  FixedSizeCache
//
//  Created by Brian Arnold on 6/19/26.
//

import Testing
@testable import FixedSizeCacheFixed

// MARK: - Diagnostic tests (expected to FAIL with the current implementation)
//
// The current eviction condition is `store.count >= capacity`, which fires as
// soon as the store reaches capacity rather than after it exceeds it. This
// causes the oldest entry to be dropped the moment the cache becomes full,
// leaving the cache perpetually one slot short. The correct condition is
// `store.count > capacity`.
//
// These tests document the precise contract at the capacity boundary so the
// bug is immediately visible when the suite runs.

@Suite("FixedSizeCache – Capacity Boundary (Diagnostic)") struct CapacityBoundaryTests {

    // Insert exactly `capacity` distinct keys.
    // Expected: every key survives — the cache is full but not over capacity.
    // Actual (buggy): the first key is evicted immediately upon the Nth insert,
    // so only capacity-1 keys remain.
    @Test func allKeysRetainedWhenCacheIsExactlyFull() {
        let capacity = 4
        var cache = FixedSizeCache<Int, Int>(capacity: capacity)

        for i in 1...capacity {
            cache.set(i * 10, forKey: i)
        }

        for i in 1...capacity {
            #expect(cache.get(forKey: i) == i * 10,
                    "key \(i) must survive when the cache holds exactly \(capacity) of \(capacity) entries")
        }
    }

    // Insert `capacity + 1` distinct keys.
    // Expected: key 1 (oldest) is evicted; keys 2 … capacity+1 all survive.
    // Actual (buggy): two keys are evicted instead of one, because eviction
    // fires one insert too early and then fires again on the final insert.
    @Test func exactlyOldestEvictedWhenCapacityExceededByOne() {
        let capacity = 4
        var cache = FixedSizeCache<Int, Int>(capacity: capacity)

        for i in 1...(capacity + 1) {
            cache.set(i * 10, forKey: i)
        }

        // The oldest key must be gone.
        #expect(cache.get(forKey: 1) == nil,
                "key 1 (oldest) must be evicted after inserting capacity+1 entries")

        // Every other key must still be present.
        for i in 2...(capacity + 1) {
            #expect(cache.get(forKey: i) == i * 10,
                    "key \(i) must survive after exactly one eviction")
        }
    }
}
