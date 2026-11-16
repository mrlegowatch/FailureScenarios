//
//  main.swift
//  FixedSizeCache
//
//  Created by Brian Arnold on 6/19/26.
//

import Foundation

// MARK: - Driver

func collatzLength(from n: Int) -> Int {
    var current = n
    var steps = 0
    while current > 1 {
        current = current.isMultiple(of: 2) ? current / 2 : 3 * current + 1
        steps += 1
    }
    return steps
}

var cache = FixedSizeCache<Int, Int>(capacity: 8)
var hits = 0
var misses = 0

// A repeating pattern of hot IDs (1–6) punctuated by occasional cold IDs
// (7–10) that expand the working set just past its steady-state size.
let requests: [Int] = [
    1, 2, 3, 4, 5, 6,
    1, 2, 3,
    7,
    4, 5, 6, 2, 3,
    8,
    1, 4, 5, 6, 3,
    9,
    1, 2, 4, 5, 6, 3,
    10,
    1, 2, 3, 4, 5, 6,
]

for id in requests {
    if let cached = cache.get(forKey: id) {
        hits += 1
        _ = cached
    } else {
        misses += 1
        cache.set(collatzLength(from: id), forKey: id)
    }
}

let total = hits + misses
let efficiency = Double(hits) / Double(total) * 100
print("Processed \(total) requests.")
print("Cache hits: \(hits)  |  misses: \(misses)  |  efficiency: \(String(format: "%.1f", efficiency))%")
