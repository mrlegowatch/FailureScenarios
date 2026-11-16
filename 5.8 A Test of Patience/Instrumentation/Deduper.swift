//
//  Deduper.swift
//  Instrumentation
//
//  Created by Brian Arnold on 6/21/26.
//

import Foundation

struct Record: Equatable {
    let id: String
    let source: String
    let value: Int
}

actor Deduper {
    private var seenRecords: [Record] = []
    private(set) var totalProcessed: Int = 0
    private(set) var lastCheckDuration: TimeInterval = 0

    func process(_ record: Record) -> Bool {
        let checkStart = Date()
        let isDuplicate = seenRecords.contains(record)
        lastCheckDuration = Date().timeIntervalSince(checkStart)
        totalProcessed += 1
        if isDuplicate { return false }
        seenRecords.append(record)
        return true
    }

    func snapshot() -> (totalProcessed: Int, seenCount: Int, lastCheckDuration: TimeInterval) {
        (totalProcessed, seenRecords.count, lastCheckDuration)
    }
}
