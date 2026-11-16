//
//  Deduper.swift
//  Baseline
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

    func process(_ record: Record) -> Bool {
        if seenRecords.contains(record) {
            return false
        }
        seenRecords.append(record)
        return true
    }
}
