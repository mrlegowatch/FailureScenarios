//
//  WorkSession.swift
//  Subscribers
//
//  Created by Brian Arnold on 6/21/26.
//

import Foundation

class WorkSession {
    private let dispatcher: Dispatcher
    private var subscriber: (any Subscriber)?
    private var results: [String] = []

    init(id: Int, dispatcher: Dispatcher) {
        self.dispatcher = dispatcher
        let subscriber = StatusSubscriber(id: id)
        self.subscriber = subscriber
        dispatcher.register(subscriber)
    }

    func process(_ events: [StatusEvent]) {
        for event in events {
            dispatcher.broadcast(event)
            results.append(event.message)
        }
    }

    func complete() {
        if let subscriber = subscriber {
            dispatcher.unregister(subscriber)
            self.subscriber = nil
        }
        flush()
    }

    func cancel() {
        results.removeAll()
        subscriber = nil
    }

    private func flush() {
        results.removeAll()
    }
}
