//
//  DiagnosticTests.swift
//  DiagnosticTests
//
//  Created by Brian Arnold on 6/21/26.
//

import Testing
import Foundation
@testable import SubscriberFixed

// .serialized prevents concurrent tests from racing on the shared InstanceTracker.
@Suite("Subscriber Lifetime", .serialized)
struct DiagnosticTests {

    @Test("cancelled WorkSession releases its subscriber")
    func cancelledSessionReleasesSubscriber() async throws {
        let baseline = await InstanceTracker.shared.liveCount
        let dispatcher = Dispatcher()

        do {
            let session = WorkSession(id: 0, dispatcher: dispatcher)
            session.cancel()
        }

        try await Task.sleep(nanoseconds: 100_000_000)

        let liveCount = await InstanceTracker.shared.liveCount
        #expect(liveCount == baseline)
    }
}
