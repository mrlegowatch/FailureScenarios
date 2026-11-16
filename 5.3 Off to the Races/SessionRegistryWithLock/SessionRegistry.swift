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
    // inFlight holds a Task for any user whose session is currently being created.
    // A concurrent caller for the same user joins the existing Task instead of
    // starting a second creation, ensuring create() fires at most once per user.
    private var inFlight: [UserID: Task<Session, Never>] = [:]
    private let lock = NSLock()

    // Default reads the environment so the driver and shell flag still work
    // unchanged. Pass addDelay: true in tests to skip the env-var requirement.
    init(addDelay: Bool = ProcessInfo.processInfo.environment["SESSIONREGISTRY_ADD_DELAY"] != nil) {
        self.addDelay = addDelay
    }

    func session(for userID: UserID, create: @escaping @Sendable () async -> Session) async -> Session {
        // Race-widening hook (testing only) — runs before the lock is acquired
        // so it does not block cooperating tasks. Because correctness is now
        // enforced by the lock, this delay no longer triggers the race.
        if addDelay {
            try? await Task.sleep(for: .milliseconds(Int.random(in: 1...5)))
        }

        // NOTE: NSLock cannot be held across an await, so the check-then-act
        // sequence is split across two locked regions bridged by the inFlight map.
        // The first task to arrive registers a Task in inFlight under the lock;
        // concurrent tasks find it and join rather than start a second creation.
        // This is correct but fragile: any future modification to this method
        // must maintain both lock regions and the inFlight handshake, or the
        // guarantee breaks silently. An actor-based implementation would make
        // the invariant impossible to violate accidentally.
        enum LookupOutcome {
            case found(Session)
            case joinPending(Task<Session, Never>)
            case registered(Task<Session, Never>)
        }

        let outcome: LookupOutcome = lock.withLock {
            if let existing = sessions[userID]  { return .found(existing) }
            if let pending  = inFlight[userID]  { return .joinPending(pending) }
            let task = Task { await create() }
            inFlight[userID] = task
            return .registered(task)
        }

        switch outcome {
        case .found(let session):
            return session
        case .joinPending(let task):
            return await task.value
        case .registered(let task):
            let session = await task.value
            lock.withLock {
                sessions[userID] = session
                inFlight[userID] = nil
            }
            return session
        }
    }

    private let addDelay: Bool
}
