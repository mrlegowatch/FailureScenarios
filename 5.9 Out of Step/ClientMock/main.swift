//
//  main.swift
//  ClientMock
//
//  Created by Brian Arnold on 6/26/26.
//

import Foundation

// MARK: - Locate Project Root

// Navigate from source file up to project root: ClientMock/ -> project root
let sourceURL = URL(fileURLWithPath: #filePath)
let projectRoot = sourceURL
    .deletingLastPathComponent()
    .deletingLastPathComponent()

// MARK: - Decode mock_data.json

let mockDataURL = projectRoot.appendingPathComponent("Fixtures/mock_data.json")
let mockData = try Data(contentsOf: mockDataURL)
let decoded = try JSONDecoder().decode([Streak].self, from: mockData)

var outputLines: [String] = []
for streak in decoded {
    let line = "id: \(streak.id), name: \(streak.name), status: \(streak.status), currentCount: \(streak.currentCount), freezesRemaining: \(streak.freezesRemaining)"
    print(line)
    outputLines.append(line)
}

// MARK: - Write Evidence

let evidenceURL = projectRoot.appendingPathComponent("Evidence/02-ClientMock-decode.txt")
try outputLines.joined(separator: "\n").write(to: evidenceURL, atomically: true, encoding: .utf8)
