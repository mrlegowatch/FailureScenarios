//
//  main.swift
//  DedupeFixed
//
//  Created by Brian Arnold on 6/21/26.
//

import Foundation

let recordCount = 50_000
let duplicateRate = 0.08

// Attaching a debugger to inspect pipeline behavior:
//
//   lldb -p $(pgrep DedupeFixed)
//
// Once attached:
//   (lldb) thread list
//   (lldb) thread backtrace all
//
// Expected observations:
//   - The consumer thread should be executing inside Set.contains (O(1)
//     hash lookup), called from Deduper.process — not in a sequential scan.
//   - The producer thread should be inside its Task body yielding records.
//   - No thread should be parked at pthread_mutex_lock, semaphore_wait,
//     dispatch_semaphore_wait, or _dispatch_sync_wait.
//   - Swift concurrency frames (swift_task_switch, _swift_concurrency_*) are
//     normal cooperative scheduling overhead, not blocking primitives.

// The signal that asks for a snapshot: SIGINFO on macOS, which Control-T sends from Terminal.
// Linux has no SIGINFO, so there it's SIGUSR1, sent with kill -USR1. Windows has no signal
// to ask with, so there the program runs without snapshots.
#if canImport(Darwin)
let snapshotSignal = SIGINFO
#elseif !os(Windows)
let snapshotSignal = SIGUSR1
#endif

func run() async {
    let processStart = Date()
    print("Processing records...")

    let deduper = Deduper()

#if !os(Windows)
    signal(snapshotSignal, SIG_IGN)
    let sigSource = DispatchSource.makeSignalSource(signal: snapshotSignal, queue: .global())
    sigSource.setEventHandler {
        Task {
            let elapsed = Date().timeIntervalSince(processStart)
            let snap = await deduper.snapshot()
            print(String(format: "[snapshot @ %.0fs]  processed=%d  seenRecords=%d  last check=%.4fs",
                         elapsed, snap.totalProcessed, snap.seenCount, snap.lastCheckDuration))
        }
    }
    sigSource.resume()
#else
    print("(Snapshots need a signal, which Windows doesn't have; run this case in WSL to try them.)")
#endif

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
        if isNew {
            uniqueCount += 1
        } else {
            duplicateCount += 1
        }
    }

    _ = await producer.value

    let elapsed = Date().timeIntervalSince(processStart)
    let snap = await deduper.snapshot()
    print(String(format: "Done. Processed: %d, Unique: %d, Duplicates: %d, Elapsed: %.2fs",
                 snap.totalProcessed, uniqueCount, duplicateCount, elapsed))
}

let semaphore = DispatchSemaphore(value: 0)
Task.detached {
    await run()
    semaphore.signal()
}
semaphore.wait()
