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

    func session(for userID: UserID, create: () async -> Session) async -> Session {
        if let existing = sessions[userID] {
            return existing
        }

        let session = await create()
        sessions[userID] = session
        return session
    }
}
