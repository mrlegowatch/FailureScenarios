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

actor SessionRegistry {
    private var sessions: [UserID: Session] = [:]
    // inFlight holds a Task for any user whose session is currently being created.
    // Actor isolation protects both dictionaries automatically: access from outside
    // requires await (enforced by the compiler), and within the actor the executor
    // guarantees no interleaving between suspension points. No lock needed, and no
    // future maintainer can accidentally bypass the synchronization.
    private var inFlight: [UserID: Task<Session, Never>] = [:]

    // Default reads the environment so the driver and shell flag still work
    // unchanged. Pass addDelay: true in tests to skip the env-var requirement.
    init(addDelay: Bool = ProcessInfo.processInfo.environment["SESSIONREGISTRY_ADD_DELAY"] != nil) {
        self.addDelay = addDelay
    }

    func session(for userID: UserID, create: @escaping @Sendable () async -> Session) async -> Session {
        // Race-widening hook (testing only) — the actor releases its executor at
        // every await point, so this sleep causes many tasks to pile up before
        // any of them registers a Task in inFlight, exercising the concurrent path.
        // Has no effect on the default code path; never enable in production.
        if addDelay {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 1...5)))
        }

        // The span from here to the first await is a single atomic unit under
        // actor isolation: no other task can observe or modify sessions or inFlight
        // until we suspend. The check-register-suspend sequence is correct by
        // construction — the compiler makes it impossible to access these
        // dictionaries from outside the actor without going through this method.
        if let existing = sessions[userID] { return existing }
        if let pending  = inFlight[userID] { return await pending.value }
        let task = Task { await create() }
        inFlight[userID] = task

        let session = await task.value
        sessions[userID] = session
        inFlight[userID] = nil
        return session
    }

    private let addDelay: Bool
}
