//
//  NewFormatFixedTests.swift
//  NewFormatFixedTests
//
//  Created by Brian Arnold on 6/26/26.
//
//  Mirrors DiagnosticTests, rewritten for the now-correct behavior:
//  no withKnownIssue wrappers — every assertion should pass.
//

import Testing
import Foundation
@testable import ClientFixed

// StreakStatus and Streak come from ClientFixed.

// Locate project root from this source file at compile time.
private let fixturesRoot = URL(fileURLWithPath: #filePath)
    .deletingLastPathComponent()  // NewFormatFixedTests/
    .deletingLastPathComponent()  // project root

// MARK: - Suite

@Suite("NewFormatFixed — correct behavior after enum-drift fix")
struct NewFormatFixedTests {

    private func loadOldData() throws -> [Streak] {
        let url = fixturesRoot.appendingPathComponent("Fixtures/old_data.json")
        return try JSONDecoder().decode([Streak].self, from: Data(contentsOf: url))
    }

    private func loadSyncedRecord() throws -> Streak {
        let url = fixturesRoot.appendingPathComponent("Fixtures/synced_record.json")
        return try JSONDecoder().decode(Streak.self, from: Data(contentsOf: url))
    }

    // MARK: Test 1 — Every record decodes to the status it held under the old schema.
    // Previously failed for ids 2, 3, 5 because frozen was inserted in the middle.
    // Fixed: version-0 path maps raw values explicitly (0→active, 1→broken, 2→completed).

    @Test func statusMatchesOldSchemaIntent() throws {
        let streaks = try loadOldData()

        // id "1" Morning Run: raw 0 → .active (unchanged in both schemas).
        #expect(streaks[0].status == .active)

        // id "2" Daily Reading: raw 1 was .broken in old schema — now correctly decoded.
        #expect(streaks[1].status == .broken)

        // id "3" 30-Day Yoga: raw 2 was .completed in old schema — now correctly decoded.
        #expect(streaks[2].status == .completed)

        // id "4" Meditation: raw 0 → .active (unchanged in both schemas).
        #expect(streaks[3].status == .active)

        // id "5" Cold Shower: raw 1 was .broken in old schema — now correctly decoded.
        #expect(streaks[4].status == .broken)
    }

    // MARK: Test 2 — Pre-versioning records carry nil freezesRemaining.
    // Previously failed because decodeIfPresent ?? 1 applied a uniform default of 1
    // to every record with the key absent.
    // Fixed: version-0 path sets freezesRemaining to nil — genuinely unknown for old data.

    @Test func oldRecordsHaveNilFreezesRemaining() throws {
        let streaks = try loadOldData()

        for streak in streaks {
            #expect(streak.freezesRemaining == nil,
                    "Pre-versioning record id \(streak.id) should have nil freezesRemaining")
        }
    }

    // MARK: Test 3 — Re-encoding a synced record preserves schemaVersion.
    // Previously failed because Streak.CodingKeys omitted schemaVersion, so JSONDecoder
    // dropped it silently and JSONEncoder never wrote it back.
    // Fixed: schemaVersion is now in CodingKeys; both decode and encode handle it.

    @Test func reEncodedSyncedRecordPreservesSchemaVersion() throws {
        let streak = try loadSyncedRecord()
        let reEncoded = try JSONEncoder().encode(streak)
        let reEncodedDict = try JSONSerialization.jsonObject(with: reEncoded) as! [String: Any]

        #expect(reEncodedDict["schemaVersion"] as? Int == 1)
    }

    // MARK: Test 4 — schemaVersion correctly identifies record vintage.
    // Old records (no schemaVersion key in source JSON) infer version 0.
    // The synced record (explicit schemaVersion: 1) decodes to version 1
    // and defaults freezesRemaining to 1 when the key is absent.

    @Test func schemaVersionDistinguishesRecordVintage() throws {
        let oldStreaks = try loadOldData()
        for streak in oldStreaks {
            #expect(streak.schemaVersion == 0,
                    "Pre-versioning record id \(streak.id) should infer schemaVersion 0")
        }

        let synced = try loadSyncedRecord()
        #expect(synced.schemaVersion == 1)
        #expect(synced.status == .active)
        #expect(synced.freezesRemaining == 1,
                "Version-1 record with no explicit freezesRemaining should default to 1")
    }
}
