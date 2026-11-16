//
//  Subscriber.swift
//  SubscriberFixedHashTableVariant
//
//  Created by Brian Arnold on 6/21/26.
//

import Foundation

// MARK: - Event tracking

actor EventTracker {
    static let shared = EventTracker()
    private(set) var liveCount: Int = 0

    func increment() { liveCount += 1 }
    func decrement() { liveCount -= 1 }
}

private final class _EventLifetime {
    init()  { Task { await EventTracker.shared.increment() } }
    deinit  { Task { await EventTracker.shared.decrement() } }
}

struct StatusEvent {
    let message: String
    let timestamp: Date
    private let _lifetime = _EventLifetime()
}

// MARK: - Subscriber tracking

actor InstanceTracker {
    static let shared = InstanceTracker()
    private(set) var liveCount: Int = 0

    func increment() { liveCount += 1 }
    func decrement() { liveCount -= 1 }
}

protocol Subscriber: AnyObject {
    var id: Int { get }
    func receive(_ event: StatusEvent)
}

class StatusSubscriber: Subscriber {
    let id: Int
    private var log: [StatusEvent] = []

    init(id: Int) {
        self.id = id
        Task { await InstanceTracker.shared.increment() }
    }

    deinit {
        Task { await InstanceTracker.shared.decrement() }
    }

    func receive(_ event: StatusEvent) {
        log.append(event)
    }
}

// MARK: - Dispatcher

class Dispatcher {
    private let subscribers = NSHashTable<AnyObject>.weakObjects()

    func register(_ subscriber: Subscriber) {
        subscribers.add(subscriber)
    }

    func broadcast(_ event: StatusEvent) {
        for case let subscriber as Subscriber in subscribers.allObjects {
            subscriber.receive(event)
        }
    }

    func unregister(_ subscriber: Subscriber) {
        subscribers.remove(subscriber)
    }

    var subscriberCount: Int { subscribers.allObjects.count }
}
