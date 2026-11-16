//
//  FitnessStreak.swift
//  NewFormatFixed
//
//  Created by Brian Arnold on 6/26/26.
//

// Raw values are persisted on device and on the server.
// Append new cases only; never insert or renumber.
enum StreakStatus: Int, Codable {
    case active = 0, broken = 1, completed = 2, frozen = 3
}

extension StreakStatus {
    // The order the picker shows. Change freely; nothing here is persisted.
    static let displayOrder: [StreakStatus] = [.active, .frozen, .broken, .completed]
}

struct Streak: Codable, Equatable {
    let id: String
    let name: String
    var status: StreakStatus
    var currentCount: Int
    var freezesRemaining: Int?  // nil = genuinely unknown (pre-versioning records)
    var schemaVersion: Int      // 0 when absent in source JSON

    enum CodingKeys: String, CodingKey {
        case id, name, status, currentCount, freezesRemaining, schemaVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id  = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        currentCount = try container.decode(Int.self, forKey: .currentCount)

        let versionPresent = container.contains(.schemaVersion)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 0

        if versionPresent {
            // Versioned record: status raw values match the current enum ordering.
            status = try container.decode(StreakStatus.self, forKey: .status)
            // Key absent → default 1.  Key present with JSON null → preserve nil
            // (genuinely unknown, e.g. a migrated v0 record re-decoded after
            // round-trip through encode(to:) which writes explicit null).
            if container.contains(.freezesRemaining) {
                freezesRemaining = try container.decodeIfPresent(Int.self, forKey: .freezesRemaining)
            } else {
                freezesRemaining = 1
            }
        } else {
            // Version 0 (pre-versioning): the client's enum inserted frozen at
            // position 1, shifting broken (1→2) and completed (2→3).
            // Map old raw values explicitly rather than trusting the new enum.
            let rawStatus = try container.decode(Int.self, forKey: .status)
            switch rawStatus {
            case 0: status = .active
            case 1: status = .broken
            case 2: status = .completed
            default:
                throw DecodingError.dataCorruptedError(
                    forKey: .status, in: container,
                    debugDescription: "Unexpected v0 status raw value: \(rawStatus)"
                )
            }
            freezesRemaining = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id,           forKey: .id)
        try container.encode(name,         forKey: .name)
        try container.encode(status,       forKey: .status)
        try container.encode(currentCount, forKey: .currentCount)
        // Write explicit JSON null for nil so that round-trip decoding can
        // distinguish "key present, value null" from "key absent" and keep nil
        // rather than applying the absent-key default of 1.
        try container.encode(freezesRemaining, forKey: .freezesRemaining)
        try container.encode(schemaVersion,    forKey: .schemaVersion)
    }
}
