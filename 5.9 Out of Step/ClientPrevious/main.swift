//
//  main.swift
//  ClientPrevious
//
//  Created by Brian Arnold on 6/26/26.
//

import Foundation

// MARK: - Data

let streaks: [Streak] = [
    Streak(id: "1", name: "Morning Run",   status: .active,    currentCount: 14),
    Streak(id: "2", name: "Daily Reading", status: .broken,    currentCount: 3),
    Streak(id: "3", name: "30-Day Yoga",   status: .completed, currentCount: 30),
    Streak(id: "4", name: "Meditation",    status: .active,    currentCount: 7),
    Streak(id: "5", name: "Cold Shower",   status: .broken,    currentCount: 0),
]

// MARK: - Encode & Write Fixture

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let jsonData = try encoder.encode(streaks)

// Navigate from source file up to project root: Baseline/ -> project root
let sourceURL = URL(fileURLWithPath: #filePath)
let projectRoot = sourceURL
    .deletingLastPathComponent()  // drop main.swift -> <target>/
    .deletingLastPathComponent()  // drop <target>/ -> project root

let fixturesDir = projectRoot.appendingPathComponent("Fixtures")
try FileManager.default.createDirectory(at: fixturesDir, withIntermediateDirectories: true)
let fixtureURL = fixturesDir.appendingPathComponent("old_data.json")
try jsonData.write(to: fixtureURL)

// MARK: - Decode & Print

let decoded = try JSONDecoder().decode([Streak].self, from: jsonData)
var outputLines: [String] = []
for streak in decoded {
    let line = "id: \(streak.id), name: \(streak.name), status: \(streak.status), currentCount: \(streak.currentCount)"
    print(line)
    outputLines.append(line)
}

// MARK: - Write Evidence

let evidenceDir = projectRoot.appendingPathComponent("Evidence")
try FileManager.default.createDirectory(at: evidenceDir, withIntermediateDirectories: true)
let evidenceURL = evidenceDir.appendingPathComponent("03-ClientPrevious-decode.txt")
try outputLines.joined(separator: "\n").write(to: evidenceURL, atomically: true, encoding: .utf8)
