//
//  main.swift
//  SessionRegistry
//
//  Created by Brian Arnold on 6/19/26.
//

import Foundation

actor CreationCounter {
    private(set) var count = 0

    func increment() {
        count += 1
    }
}

// MARK: - Driver

let userPool: [UserID] = (1...8).map { "user\($0)" }
let requestCount = 80
let registry = SessionRegistry()
let creationCounter = CreationCounter()

var observations: [(userID: UserID, token: String)] = []

await withTaskGroup(of: (UserID, String).self) { group in
    for i in 0..<requestCount {
        let userID = userPool[i % userPool.count]
        group.addTask {
            let session = await registry.session(for: userID) {
                await creationCounter.increment()
                try? await Task.sleep(for: .milliseconds(5))
                return Session(userID: userID)
            }
            return (userID, session.token)
        }
    }

    for await (userID, token) in group {
        observations.append((userID: userID, token: token))
    }
}

// MARK: - Summary

let distinctUsers = Set(observations.map(\.userID)).sorted()
let totalCreations = await creationCounter.count

print("Total requests   : \(observations.count)")
print("Distinct users   : \(distinctUsers.count)")
print("Session creations: \(totalCreations) (expected \(distinctUsers.count); excess = \(totalCreations - distinctUsers.count))")
print()

for userID in distinctUsers {
    let tokens = observations.filter { $0.userID == userID }.map(\.token)
    let distinctTokens = Set(tokens)
    let flag = distinctTokens.count > 1 ? "  <-- RACE: \(distinctTokens.count) distinct tokens" : ""
    print("\(userID): \(tokens.count) requests, \(distinctTokens.count) distinct token(s)\(flag)")
}
