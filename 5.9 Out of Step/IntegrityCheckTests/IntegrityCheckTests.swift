//
//  IntegrityCheckTests.swift
//  IntegrityCheckTests
//
//  Created by Brian Arnold on 6/26/26.
//

import Testing
import Foundation
@testable import IntegrityCheck

// StreakStatus and Streak come from IntegrityCheck.

// MARK: - Inline JSON helpers (no fixture files used in this suite)

private func decodeStreak(_ json: String) throws -> Streak {
    try JSONDecoder().decode(Streak.self, from: Data(json.utf8))
}

private func roundTrip(_ streak: Streak) throws -> Streak {
    let data = try JSONEncoder().encode(streak)
    return try JSONDecoder().decode(Streak.self, from: data)
}

// MARK: - Test suite

@Suite struct IntegrityCheckTests {

    // MARK: Status round-trips for all four enum cases

    @Test func activeStatusRoundTrips() throws {
        let streak = try decodeStreak(
            #"{"id":"1","name":"Test","status":0,"currentCount":5}"#
        )
        #expect(streak.status == .active)
        #expect(try roundTrip(streak).status == .active)
    }

    @Test func frozenStatusRoundTrips() throws {
        let streak = try decodeStreak(
            #"{"id":"1","name":"Test","status":1,"currentCount":5}"#
        )
        #expect(streak.status == .frozen)
        #expect(try roundTrip(streak).status == .frozen)
    }

    @Test func brokenStatusRoundTrips() throws {
        let streak = try decodeStreak(
            #"{"id":"1","name":"Test","status":2,"currentCount":5}"#
        )
        #expect(streak.status == .broken)
        #expect(try roundTrip(streak).status == .broken)
    }

    @Test func completedStatusRoundTrips() throws {
        let streak = try decodeStreak(
            #"{"id":"1","name":"Test","status":3,"currentCount":5}"#
        )
        #expect(streak.status == .completed)
        #expect(try roundTrip(streak).status == .completed)
    }

    // MARK: freezesRemaining defaulting when absent

    @Test func freezesRemainingDefaultsToOneWhenAbsent() throws {
        let streak = try decodeStreak(
            #"{"id":"1","name":"Test","status":0,"currentCount":5}"#
        )
        #expect(streak.freezesRemaining == 1)
    }

    // MARK: Explicit freezesRemaining values honored

    @Test func freezesRemainingZeroIsHonored() throws {
        let streak = try decodeStreak(
            #"{"id":"2","name":"Test","status":2,"currentCount":0,"freezesRemaining":0}"#
        )
        #expect(streak.freezesRemaining == 0)
    }

    @Test func freezesRemainingNonDefaultValueIsHonored() throws {
        let streak = try decodeStreak(
            #"{"id":"4","name":"Test","status":1,"currentCount":7,"freezesRemaining":3}"#
        )
        #expect(streak.freezesRemaining == 3)
    }
}
