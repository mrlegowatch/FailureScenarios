//
//  main.swift
//  ClientCurrent
//
//  Created by Brian Arnold on 6/26/26.
//

import Foundation

// MARK: - Helpers for showing what the old schema intended

// User-reported status: active=0, broken=1, completed=2
func userReportedName(forRaw raw: Int) -> String {
    switch raw {
    case 0: return "active"
    case 1: return "broken"
    case 2: return "completed"
    default: return "(no case)"
    }
}


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
let rule = String(repeating: "-", count: 72)

// MARK: - Part 1: Decode old_data.json

let oldDataURL = projectRoot.appendingPathComponent("Fixtures/old_data.json")
let rawData = try Data(contentsOf: oldDataURL)
let decoded = try JSONDecoder().decode([Streak].self, from: rawData)

emit("Decoded old_data.json:")
emit("")
for streak in decoded {
    emit("id: \(streak.id), name: \(streak.name), status: \(streak.status), currentCount: \(streak.currentCount), freezesRemaining: \(streak.freezesRemaining)")
}

// MARK: - Part 2: Compare with what the user reported

emit("")
emit("Status comparison — schema decode vs. expected:")
emit(rule)
for streak in decoded {
    let raw = streak.status.rawValue
    let userReported = userReportedName(forRaw: raw)
    let newDecoded = String(describing: streak.status)
    emit("id \(streak.id)  \(streak.name): raw status=\(raw)  ->  decoded .\(newDecoded) (expected: \(userReported))")
}

// MARK: - Part 3: freezesRemaining as decoded, and whether the key was in the file

let rawRecords = try JSONSerialization.jsonObject(with: rawData) as! [[String: Any]]
emit("")
emit("freezesRemaining — decoded value vs. key in old_data.json:")
emit(rule)
for (streak, record) in zip(decoded, rawRecords) {
    let present = record["freezesRemaining"] != nil ? "YES" : "NO"
    emit("id \(streak.id)  \(streak.name): decoded=\(streak.freezesRemaining)  key present: \(present)")
}

// MARK: - Part 4: schemaVersion side-by-side and silent-ignore demonstration

// Extract id "1" record from old_data.json as pretty JSON text for side-by-side display
let oldArray = try JSONSerialization.jsonObject(with: rawData) as! [[String: Any]]
let firstRecord = oldArray[0]
let keyOrder = ["id", "name", "status", "currentCount", "schemaVersion"]
let presentKeys = keyOrder.filter { firstRecord[$0] != nil }
var jsonLines = ["{"]
for (i, key) in presentKeys.enumerated() {
    let value = firstRecord[key]!
    let valueStr = (value as? String).map { "\"\($0)\"" } ?? "\(value)"
    let comma = i < presentKeys.count - 1 ? "," : ""
    jsonLines.append("  \"\(key)\" : \(valueStr)\(comma)")
}
jsonLines.append("}")
let firstRecordText = jsonLines.joined(separator: "\n")
    .trimmingCharacters(in: .newlines)

let syncedURL = projectRoot.appendingPathComponent("Fixtures/synced_record.json")
let syncedData = try Data(contentsOf: syncedURL)
let syncedText = String(data: syncedData, encoding: .utf8)!
    .trimmingCharacters(in: .newlines)

emit("")
let leftHeader  = "old_data.json (id \"1\")"
let rightHeader = "synced_record.json"
let colWidth = 28
emit(leftHeader.padding(toLength: colWidth, withPad: " ", startingAt: 0) + "  " + rightHeader)
emit(String(repeating: "-", count: colWidth) + "  " + String(repeating: "-", count: rightHeader.count))
let leftLines  = firstRecordText.components(separatedBy: "\n")
let rightLines = syncedText.components(separatedBy: "\n")
for i in 0..<max(leftLines.count, rightLines.count) {
    let left  = i < leftLines.count  ? leftLines[i]  : ""
    let right = i < rightLines.count ? rightLines[i] : ""
    emit(left.padding(toLength: colWidth, withPad: " ", startingAt: 0) + "  " + right)
}

emit("")
emit("Decode synced_record.json with current Streak type:")
let syncedStreak = try JSONDecoder().decode(Streak.self, from: syncedData)
emit("id: \(syncedStreak.id), name: \(syncedStreak.name), status: \(syncedStreak.status), currentCount: \(syncedStreak.currentCount), freezesRemaining: \(syncedStreak.freezesRemaining)")

// MARK: - Part 5: Server ordering vs. client ordering

// The server's StreakStatus, as its schema defines it: frozen appended at the end.
let serverNames = ["active", "broken", "completed", "frozen"]
func clientName(forRaw raw: Int) -> String {
    StreakStatus(rawValue: raw).map { String(describing: $0) } ?? "(no case)"
}

emit("")
var serverRow = "Server ordering:  "
var clientRow = "Client ordering:  "
for raw in 0..<serverNames.count {
    let serverCell = "\(serverNames[raw])=\(raw)"
    let clientCell = "\(clientName(forRaw: raw))=\(raw)"
    let width = max(serverCell.count, clientCell.count) + 2
    serverRow += serverCell.padding(toLength: width, withPad: " ", startingAt: 0)
    clientRow += clientCell.padding(toLength: width, withPad: " ", startingAt: 0)
}
emit(serverRow.trimmingCharacters(in: .whitespaces))
emit(clientRow.trimmingCharacters(in: .whitespaces))
emit(rule)
for raw in 0..<serverNames.count {
    let server = serverNames[raw]
    let client = clientName(forRaw: raw)
    guard server != client else { continue }
    let serverCol = "server=.\(server),".padding(toLength: 19, withPad: " ", startingAt: 0)
    let clientCol = "client=.\(client)".padding(toLength: 18, withPad: " ", startingAt: 0)
    emit("raw \(raw): \(serverCol)\(clientCol)— \(server) streaks silently appear \(client)")
}

// MARK: - Write Evidence

let evidenceURL = projectRoot.appendingPathComponent("Evidence/01-ClientCurrent-decode.txt")
try outputLines.joined(separator: "\n").write(to: evidenceURL, atomically: true, encoding: .utf8)
