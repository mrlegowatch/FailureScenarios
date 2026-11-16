//
//  DiagnosticTests.swift
//  DiagnosticTests
//
//  Created by Brian Arnold on 6/26/26.
//
//  DIAGNOSTIC SUITE — all three tests are expected to fail against the current
//  (buggy) code. Each failing assertion is wrapped in withKnownIssue so the
//  suite records the bugs without blocking. When the underlying code is fixed,
//  the known issues will flip to "unexpectedly passed".
//

import Testing
import Foundation
@testable import IntegrityCheck

// StreakStatus and Streak come from IntegrityCheck.

// Locate project root from this source file at compile time.
private let fixturesRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // DiagnosticTests/
    .deletingLastPathComponent()  // project root

// MARK: - Suite

@Suite("Diagnostic — expected to fail against current (buggy) code")
struct DiagnosticTests {

    private func loadOldData() throws -> [Streak] {
        let url = fixturesRoot.appendingPathComponent("Fixtures/old_data.json")
        return try JSONDecoder().decode([Streak].self, from: Data(contentsOf: url))
    }

    private func loadSyncedRecord() throws -> Streak {
        let url = fixturesRoot.appendingPathComponent("Fixtures/synced_record.json")
        return try JSONDecoder().decode(Streak.self, from: Data(contentsOf: url))
    }

    // MARK: Test 1 — Status should match what each record meant under the old schema.
    // Fails for ids 2, 3, 5 due to enum drift (frozen inserted in the middle shifts
    // every raw value above 0 to a different case).

    @Test func statusMatchesOldSchemaIntent() throws {
        let streaks = try loadOldData()

        // id "1" Morning Run: raw 0 was .active in old schema — decodes correctly.
        #expect(streaks[0].status == .active)

        // id "2" Daily Reading: raw 1 was .broken in old schema, decodes as .frozen.
        withKnownIssue("Enum drift: raw 1 is .broken in old schema, .frozen in new") {
            #expect(streaks[1].status == .broken)
        }

        // id "3" 30-Day Yoga: raw 2 was .completed in old schema, decodes as .broken.
        withKnownIssue("Enum drift: raw 2 is .completed in old schema, .broken in new") {
            #expect(streaks[2].status == .completed)
        }

        // id "4" Meditation: raw 0 was .active in old schema — decodes correctly.
        #expect(streaks[3].status == .active)

        // id "5" Cold Shower: raw 1 was .broken in old schema, decodes as .frozen.
        withKnownIssue("Enum drift: raw 1 is .broken in old schema, .frozen in new") {
            #expect(streaks[4].status == .broken)
        }
    }

    // MARK: Test 2 — Records that were already broken should have freezesRemaining == 0.
    // Fails because decodeIfPresent ?? 1 applies a uniform default of 1 to every
    // record whose source JSON lacks the key — regardless of what the status means.

    @Test func brokenRecordsHaveZeroFreezesRemaining() throws {
        let streaks = try loadOldData()

        // id "2" Daily Reading: was .broken in old schema — expect 0 freezes remaining.
        withKnownIssue("Uniform default of 1 applied; broken records should decode to 0") {
            #expect(streaks[1].freezesRemaining == 0)
        }

        // id "5" Cold Shower: was .broken in old schema — expect 0 freezes remaining.
        withKnownIssue("Uniform default of 1 applied; broken records should decode to 0") {
            #expect(streaks[4].freezesRemaining == 0)
        }
    }

    // MARK: Test 3 — Re-encoding a synced record should preserve the schemaVersion key.
    // Fails because Streak.CodingKeys does not include schemaVersion, so JSONDecoder
    // drops it silently on decode and JSONEncoder never writes it back out.

    @Test func reEncodedSyncedRecordPreservesSchemaVersion() throws {
        let streak = try loadSyncedRecord()
        let reEncoded = try JSONEncoder().encode(streak)
        let reEncodedDict = try JSONSerialization.jsonObject(with: reEncoded) as! [String: Any]

        withKnownIssue("Streak.CodingKeys omits schemaVersion — dropped on decode, absent from re-encode") {
            #expect(reEncodedDict["schemaVersion"] != nil)
        }
    }
}
