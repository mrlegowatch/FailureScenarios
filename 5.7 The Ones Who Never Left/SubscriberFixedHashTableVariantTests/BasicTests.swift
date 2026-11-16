//
//  BasicTests.swift
//  BasicTests
//
//  Created by Brian Arnold on 6/21/26.
//

import Testing
import Foundation
@testable import SubscriberFixedHashTableVariant

// Tracks receive(_:) calls without storing in StatusSubscriber's private log.
private class SpySubscriber: Subscriber {
    let id: Int
    var receiveCount = 0

    init(id: Int) {
        self.id = id
    }

    func receive(_ event: StatusEvent) {
        receiveCount += 1
    }
}

@Suite("Dispatcher")
struct DispatcherTests {

    @Test("register adds subscriber")
    func registration() {
        let dispatcher = Dispatcher()
        let subscriber = StatusSubscriber(id: 1)
        dispatcher.register(subscriber)
        #expect(dispatcher.subscriberCount == 1)
    }

    @Test("broadcast delivers event to each registered subscriber")
    func broadcasting() {
        let dispatcher = Dispatcher()
        let spyA = SpySubscriber(id: 1)
        let spyB = SpySubscriber(id: 2)
        dispatcher.register(spyA)
        dispatcher.register(spyB)

        dispatcher.broadcast(StatusEvent(message: "ping", timestamp: Date()))

        #expect(spyA.receiveCount == 1)
        #expect(spyB.receiveCount == 1)
    }

    @Test("unregistered subscriber no longer receives broadcasts")
    func explicitUnregister() {
        let dispatcher = Dispatcher()
        let spy = SpySubscriber(id: 1)
        dispatcher.register(spy)
        dispatcher.unregister(spy)

        dispatcher.broadcast(StatusEvent(message: "ping", timestamp: Date()))

        #expect(spy.receiveCount == 0)
    }
}

@Suite("WorkSession")
struct WorkSessionTests {

    @Test("complete unregisters subscriber from dispatcher")
    func normalCompletion() {
        let dispatcher = Dispatcher()
        let session = WorkSession(id: 1, dispatcher: dispatcher)
        #expect(dispatcher.subscriberCount == 1)

        session.complete()

        #expect(dispatcher.subscriberCount == 0)
    }
}
