//
//  main.swift
//  Subscribers
//
//  Created by Brian Arnold on 6/21/26.
//

import Foundation

let sessionCount = 300
let dispatcher = Dispatcher()

let sampleEvents = [
    StatusEvent(message: "startup",      timestamp: Date()),
    StatusEvent(message: "heartbeat",    timestamp: Date()),
    StatusEvent(message: "status-check", timestamp: Date()),
]

var normalCount = 0
var cancelledCount = 0

for i in 0..<sessionCount {
    let session = WorkSession(id: i, dispatcher: dispatcher)
    session.process(sampleEvents)

    if i % 10 < 7 {
        session.complete()
        normalCount += 1
    } else {
        session.cancel()
        cancelledCount += 1
    }
}

// The detached task below runs off the main actor, so it reports copies of these.
let normalCompletions = normalCount
let cancellations = cancelledCount
let dispatcherRetained = dispatcher.subscriberCount

let sema = DispatchSemaphore(value: 0)
Task.detached {
    try? await Task.sleep(nanoseconds: 100_000_000)
    let liveCount = await InstanceTracker.shared.liveCount

    print("Sessions run:         \(sessionCount)")
    print("Normal completions:   \(normalCompletions)")
    print("Cancellations:        \(cancellations)")
    print("Subscribers live:     \(liveCount)")
    print("Dispatcher retained:  \(dispatcherRetained)")

    sema.signal()
}
sema.wait()
