//
//  main.swift
//  Baseline
//
//  Created by Brian Arnold on 6/21/26.
//

import Foundation

let recordCount = 50_000
let duplicateRate = 0.08

func run() async {
    print("Processing records...")
    let start = Date()

    let deduper = Deduper()
    var totalProcessed = 0
    var uniqueCount = 0
    var duplicateCount = 0

    let (stream, continuation) = AsyncStream<Record>.makeStream()

    let producer = Task {
        var pool: [Record] = []
        let sources = ["web", "mobile", "api", "batch"]
        for _ in 0..<recordCount {
            let record: Record
            if !pool.isEmpty && Double.random(in: 0..<1) < duplicateRate {
                record = pool[Int.random(in: 0..<pool.count)]
            } else {
                record = Record(
                    id: UUID().uuidString,
                    source: sources.randomElement()!,
                    value: Int.random(in: 1...10_000)
                )
                pool.append(record)
            }
            continuation.yield(record)
        }
        continuation.finish()
    }

    for await record in stream {
        let isNew = await deduper.process(record)
        totalProcessed += 1
        if isNew {
            uniqueCount += 1
        } else {
            duplicateCount += 1
        }
    }

    _ = await producer.value

    let elapsed = Date().timeIntervalSince(start)
    print(String(format: "Done. Processed: %d, Unique: %d, Duplicates: %d, Elapsed: %.2fs",
                 totalProcessed, uniqueCount, duplicateCount, elapsed))
}

let semaphore = DispatchSemaphore(value: 0)
Task.detached {
    await run()
    semaphore.signal()
}
semaphore.wait()
