//
//  main.swift
//  NewFormatFixed
//
//  Created by Brian Arnold on 6/26/26.
//

import Foundation

// MARK: - Locate project root

let sourceURL = URL(fileURLWithPath: #filePath)
let projectRoot = sourceURL
    .deletingLastPathComponent()  // drop main.swift -> <target>/
    .deletingLastPathComponent()  // drop <target>/ -> project root

// MARK: - Output helpers

var outputLines: [String] = []
@MainActor func emit(_ line: String) {
    print(line)
    outputLines.append(line)
}
let rule = String(repeating: "-", count: 64)

func describe(_ s: Streak) -> String {
    let fr = s.freezesRemaining.map { "\($0)" } ?? "nil"
    return "id: \(s.id), name: \(s.name), status: \(s.status), " +
           "currentCount: \(s.currentCount), freezesRemaining: \(fr), schemaVersion: \(s.schemaVersion)"
}

// MARK: - Decode old_data.json

let oldDataURL = projectRoot.appendingPathComponent("Fixtures/old_data.json")
let oldDecoded = try JSONDecoder().decode([Streak].self, from: Data(contentsOf: oldDataURL))

emit("Fixtures/old_data.json decoded with fixed types:")
emit("")
for streak in oldDecoded {
    emit("  \(describe(streak))")
}

// MARK: - Decode synced_record.json

let syncedURL = projectRoot.appendingPathComponent("Fixtures/synced_record.json")
let syncedRecord = try JSONDecoder().decode(Streak.self, from: Data(contentsOf: syncedURL))

emit("")
emit("Fixtures/synced_record.json decoded with fixed types:")
emit("")
emit("  \(describe(syncedRecord))")

// MARK: - Structural integrity check

let allDecoded: [Streak] = oldDecoded + [syncedRecord]
let allLabels:  [String] = Array(repeating: "old_data.json", count: oldDecoded.count) + ["synced_record.json"]

emit("")
emit("Structural integrity check (re-encode, re-decode, round-trip):")
emit(String(repeating: "=", count: 64))

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

emit("")
emit("Step 1 — Re-encode each record")
emit(rule)
var encodedRecords: [Data] = []
var allWellFormed = true
for i in 0..<allDecoded.count {
    let data = try encoder.encode(allDecoded[i])
    let wellFormed = (try? JSONSerialization.jsonObject(with: data)) != nil
    if !wellFormed { allWellFormed = false }
    encodedRecords.append(data)
    emit("  id \(allDecoded[i].id) (\(allLabels[i])): \(data.count) bytes  well-formed: \(wellFormed ? "YES" : "NO")")
}
emit("  All well-formed: \(allWellFormed ? "YES" : "NO")")

emit("")
emit("Step 2 — Re-decode and compare")
emit(rule)
var allMatch = true
for i in 0..<allDecoded.count {
    let second = try JSONDecoder().decode(Streak.self, from: encodedRecords[i])
    let match  = allDecoded[i] == second
    if !match { allMatch = false }
    emit("  id \(allDecoded[i].id) (\(allLabels[i])): \(match ? "MATCH" : "MISMATCH")")
    if !match {
        emit("    first:  \(describe(allDecoded[i]))")
        emit("    second: \(describe(second))")
    }
}

emit("")
emit(String(repeating: "=", count: 64))
let pass = allWellFormed && allMatch
emit(pass ? "RESULT: PASS" : "RESULT: FAIL")
if pass {
    emit("")
    emit("All \(allDecoded.count) records survive the encode/decode round trip unchanged.")
}

// MARK: - Write Evidence

let evidenceURL = projectRoot.appendingPathComponent("Evidence/05-ClientFixed-decode.txt")
try outputLines.joined(separator: "\n").write(to: evidenceURL, atomically: true, encoding: .utf8)
