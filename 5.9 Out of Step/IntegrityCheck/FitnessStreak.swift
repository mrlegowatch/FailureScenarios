//
//  FitnessStreak.swift
//  IntegrityCheck
//
//  Created by Brian Arnold on 6/26/26.
//

enum StreakStatus: Int, Codable {
    case active = 0, frozen = 1, broken = 2, completed = 3
}

struct Streak: Codable, Equatable {
    let id: String
    let name: String
    var status: StreakStatus
    var currentCount: Int
    var freezesRemaining: Int = 1

    enum CodingKeys: String, CodingKey {
        case id, name, status, currentCount, freezesRemaining
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        status = try container.decode(StreakStatus.self, forKey: .status)
        currentCount = try container.decode(Int.self, forKey: .currentCount)
        freezesRemaining = try container.decodeIfPresent(Int.self, forKey: .freezesRemaining) ?? 1
    }
}
