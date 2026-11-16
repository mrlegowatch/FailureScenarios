//
//  FixedSizeCacheTests.swift
//  FixedSizeCache
//
//  Created by Brian Arnold on 6/19/26.
//

import Testing
@testable import FixedSizeCache

@Suite("FixedSizeCache") struct FixedSizeCacheTests {

    // MARK: - Basic storage

    @Test func storesAndRetrievesValue() {
        var cache = FixedSizeCache<String, Int>(capacity: 4)
        cache.set(42, forKey: "answer")
        #expect(cache.get(forKey: "answer") == 42)
    }

    @Test func returnsNilForAbsentKey() {
        let cache = FixedSizeCache<String, Int>(capacity: 4)
        #expect(cache.get(forKey: "missing") == nil)
    }

    @Test func overwritePreservesLatestValue() {
        var cache = FixedSizeCache<String, Int>(capacity: 4)
        cache.set(1, forKey: "x")
        cache.set(2, forKey: "x")
        #expect(cache.get(forKey: "x") == 2)
    }

    // MARK: - Capacity

    @Test func allEntriesPresentWhenBelowCapacity() {
        // Insert well under capacity; every entry must survive.
        var cache = FixedSizeCache<Int, String>(capacity: 8)
        for i in 1...5 {
            cache.set("v\(i)", forKey: i)
        }
        for i in 1...5 {
            #expect(cache.get(forKey: i) == "v\(i)")
        }
    }

    @Test func oldestEntryEvictedAfterOverfill() {
        // Insert capacity+2 entries; the first two must be gone.
        var cache = FixedSizeCache<Int, Int>(capacity: 4)
        for i in 1...6 {
            cache.set(i * 10, forKey: i)
        }
        #expect(cache.get(forKey: 1) == nil)
        #expect(cache.get(forKey: 2) == nil)
        #expect(cache.get(forKey: 6) == 60)
    }

    @Test func recentEntriesSurviveEviction() {
        // Insert 9 items into a capacity-6 cache; the last three are safely
        // within any reasonable survival window.
        var cache = FixedSizeCache<Int, Int>(capacity: 6)
        for i in 1...9 {
            cache.set(i, forKey: i)
        }
        #expect(cache.get(forKey: 7) == 7)
        #expect(cache.get(forKey: 8) == 8)
        #expect(cache.get(forKey: 9) == 9)
    }

    // MARK: - Update semantics

    @Test func updatingKeyDoesNotEvictNeighbors() {
        // Three entries in a capacity-6 cache — no eviction should occur on update.
        var cache = FixedSizeCache<Int, String>(capacity: 6)
        cache.set("a", forKey: 1)
        cache.set("b", forKey: 2)
        cache.set("c", forKey: 3)
        cache.set("A", forKey: 1)
        #expect(cache.get(forKey: 1) == "A")
        #expect(cache.get(forKey: 2) == "b")
        #expect(cache.get(forKey: 3) == "c")
    }

    @Test func updatingKeyDoesNotAlterInsertionOrderForOtherKeys() {
        // Fill slightly below capacity, update one key, then overfill by one.
        // The key evicted should be the originally-first-inserted key, not the
        // updated one.
        var cache = FixedSizeCache<Int, Int>(capacity: 6)
        for i in 1...4 {
            cache.set(i, forKey: i)
        }
        cache.set(99, forKey: 1)   // update key 1 in place
        cache.set(5, forKey: 5)
        cache.set(6, forKey: 6)
        cache.set(7, forKey: 7)    // push two past capacity: oldest keys evicted
        // Keys 4–7 are definitely recent enough to survive.
        #expect(cache.get(forKey: 4) == 4)
        #expect(cache.get(forKey: 5) == 5)
        #expect(cache.get(forKey: 6) == 6)
        #expect(cache.get(forKey: 7) == 7)
    }
}
