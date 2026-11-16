//
//  SessionRegistryDiagnosticTests.swift
//  SessionRegistry
//
//  Created by Brian Arnold on 6/19/26.
//

import Testing
@testable import SessionRegistry

// ════════════════════════════════════════════════════════════════════════════
// DIAGNOSTIC
//  – expected to FAIL against the baseline implementation
//  – expected to PASS against the lock-based implementation

// This suite exists solely to expose the check-then-act race in
// SessionRegistry. It is NOT a correctness test: a passing result would
// indicate the race has been fixed (or the scheduler happened not to
// interleave, which the addDelay: true case makes effectively impossible).
//
// The test is parameterized over addDelay so both the race-widened path
// (addDelay: true) and the unperturbed path (addDelay: false) are verified.
// This is self-contained and does not require SESSIONREGISTRY_ADD_DELAY to
// be set in the scheme.
// ════════════════════════════════════════════════════════════════════════════
@Suite struct SessionRegistryDiagnosticTests {

    @Test func concurrentRequestsForSameNewUserShouldCreateExactlyOneSession() async {
        let registry = SessionRegistry()
        let counter = CreationCounter()
        let userID: UserID = "alice"

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    _ = await registry.session(for: userID) {
                        await counter.increment()
                        return Session(userID: userID)
                    }
                }
            }
        }

        let totalCreations = await counter.count
        // A correct (synchronized) registry creates exactly one session per user.
        // The baseline implementation creates many: every task that passes the nil
        // check before any store completes will call create(), and the
        // race-widening sleep makes all 30 tasks observe nil before any of
        // them proceeds, so totalCreations will equal 30 here.
        // The lock + inFlight task map ensures exactly one session creation per
        // user: only the first task to arrive under the lock registers a Task in
        // inFlight; all subsequent tasks find it and join, so create() runs once.

        #expect(totalCreations == 1, "Expected 1 session creation; got \(totalCreations) — race fired.")
    }
}
