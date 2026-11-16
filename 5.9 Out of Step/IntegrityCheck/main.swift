//
//  main.swift
//  IntegrityCheck
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
let rule = String(repeating: "-", count: 52)

// MARK: - Load

let oldDataURL = projectRoot.appendingPathComponent("Fixtures/old_data.json")
let rawData = try Data(contentsOf: oldDataURL)

emit("INTEGRITY CHECK: Fixtures/old_data.json")
emit(String(repeating: "=", count: 52))

// MARK: - Step 1: First decode

emit("")
emit("Step 1 — Decode")
emit(rule)
let firstDecode = try JSONDecoder().decode([Streak].self, from: rawData)
for s in firstDecode {
    emit("  id \(s.id)  \(s.name): status=.\(s.status)  currentCount=\(s.currentCount)  freezesRemaining=\(s.freezesRemaining)")
}
emit("  \(firstDecode.count) records decoded  [OK]")

// MARK: - Step 2: Re-encode each record, confirm well-formed JSON

emit("")
emit("Step 2 — Re-encode each record")
emit(rule)
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
var encodedRecords: [Data] = []
var allWellFormed = true
for s in firstDecode {
    let data = try encoder.encode(s)
    let wellFormed = (try? JSONSerialization.jsonObject(with: data)) != nil
    if !wellFormed { allWellFormed = false }
    encodedRecords.append(data)
    emit("  id \(s.id)  \(s.name): \(data.count) bytes  well-formed JSON: \(wellFormed ? "YES" : "NO")")
}
emit("  All records well-formed: \(allWellFormed ? "YES" : "NO")")

// MARK: - Step 3: Second decode from re-encoded data

emit("")
emit("Step 3 — Decode re-encoded records")
emit(rule)
var secondDecode: [Streak] = []
for data in encodedRecords {
    let s = try JSONDecoder().decode(Streak.self, from: data)
    secondDecode.append(s)
    emit("  id \(s.id)  \(s.name): status=.\(s.status)  currentCount=\(s.currentCount)  freezesRemaining=\(s.freezesRemaining)")
}
emit("  \(secondDecode.count) records decoded  [OK]")

// MARK: - Step 4: Round-trip comparison

emit("")
emit("Step 4 — Round-trip comparison (first decode == second decode)")
emit(rule)
var allMatch = true
for (first, second) in zip(firstDecode, secondDecode) {
    let match = first == second
    if !match { allMatch = false }
    emit("  id \(first.id)  \(first.name): \(match ? "MATCH" : "MISMATCH")")
}

// MARK: - Summary

emit("")
emit(String(repeating: "=", count: 52))
let pass = allWellFormed && allMatch
emit(pass ? "RESULT: PASS" : "RESULT: FAIL")
emit("")
if pass {
    emit("All \(firstDecode.count) records survive the encode/decode round trip")
    emit("unchanged.")
}

// MARK: - Write Evidence

let evidenceURL = projectRoot.appendingPathComponent("Evidence/04-IntegrityCheck-report.txt")
try outputLines.joined(separator: "\n").write(to: evidenceURL, atomically: true, encoding: .utf8)
