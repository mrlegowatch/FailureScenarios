//
//  FitnessStreak.swift
//  ClientPrevious
//
//  Created by Brian Arnold on 6/26/26.
//

enum StreakStatus: Int, Codable {
    case active = 0, broken = 1, completed = 2
}

struct Streak: Codable {
    let id: String
    let name: String
    var status: StreakStatus
    var currentCount: Int
}
