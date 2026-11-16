//
//  main.swift
//  SubscriberFixedHashTableVariant
//
//  Created by Brian Arnold on 7/26/26.
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
let uniqueEvents = sampleEvents.count

let sema = DispatchSemaphore(value: 0)
Task.detached {
    try? await Task.sleep(nanoseconds: 100_000_000)
    let subscriberLiveCount = await InstanceTracker.shared.liveCount
    let eventLiveCount = await EventTracker.shared.liveCount

    print("Sessions run:         \(sessionCount)")
    print("Normal completions:   \(normalCompletions)")
    print("Cancellations:        \(cancellations)")
    print("")
    print("Subscribers live:     \(subscriberLiveCount)")
    print("Dispatcher retained:  \(dispatcherRetained)")
    print("")
    print("Event payloads live:  \(eventLiveCount)  (\(uniqueEvents) unique values × \(sessionCount) sessions = \(uniqueEvents * sessionCount) total dispatches)")

    sema.signal()
}
sema.wait()
