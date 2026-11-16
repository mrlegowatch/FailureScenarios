//
//  SessionRegistry.swift
//  SessionRegistry
//
//  Created by Brian Arnold on 7/15/26.
//

import Foundation

typealias UserID = String

struct Session {
    let userID: UserID
    let token: String
    let createdAt: Date

    init(userID: UserID) {
        self.userID = userID
        self.token = UUID().uuidString
        self.createdAt = Date()
    }
}

class SessionRegistry {
    private var sessions: [UserID: Session] = [:]
    private let lock = NSLock()

    // Default reads the environment so the driver and shell flag still work
    // unchanged. Pass addDelay: true in tests to skip the env-var requirement.
    init(addDelay: Bool = ProcessInfo.processInfo.environment["SESSIONREGISTRY_ADD_DELAY"] != nil) {
        self.addDelay = addDelay
    }

    func session(for userID: UserID, create: () async -> Session) async -> Session {
        // Race-widening hook (testing only) — runs before the lock is acquired
        // so it does not block cooperating tasks. Because correctness is now
        // enforced by the lock, this delay no longer triggers the race.
        if addDelay {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 1...5)))
        }

        if let existing = lock.withLock({ sessions[userID] }) {
            return existing
        }
        let session = await create()
        lock.withLock {
            sessions[userID] = session
        }
        return session
    }
    
    private let addDelay: Bool
}
