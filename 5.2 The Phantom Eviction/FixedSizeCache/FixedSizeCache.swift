//
//  FixedSizeCache.swift
//  FixedSizeCache
//
//  Created by Brian Arnold on 6/19/26.
//

import Foundation

struct FixedSizeCache<Key: Hashable, Value> {
    private let capacity: Int
    private var store: [Key: Value] = [:]
    private var insertionOrder: [Key] = []

    init(capacity: Int) {
        self.capacity = capacity
    }

    mutating func set(_ value: Value, forKey key: Key) {
        if store[key] == nil {
            insertionOrder.append(key)
        }
        store[key] = value

        if store.count >= capacity {
            let oldest = insertionOrder.removeFirst()
            store.removeValue(forKey: oldest)
        }
    }

    func get(forKey key: Key) -> Value? {
        return store[key]
    }
}
