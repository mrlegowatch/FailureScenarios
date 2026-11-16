//
//  main.swift
//  LimitedSelection
//
//  Created by Brian Arnold on 6/19/26.
//

import Foundation
import WaitOnSelect

let defaultFileDescriptorCount = 300

let fileDescriptorCount: Int
if CommandLine.arguments.count > 1, let count = Int(CommandLine.arguments[1]) {
    fileDescriptorCount = count
} else {
    fileDescriptorCount = defaultFileDescriptorCount
}

if fileDescriptorCount > 0 {
    // Open many file handles to attempt to recreate issue caused by calling select()
    for i in 0..<fileDescriptorCount {
        _ = fopen("/tmp/Dummy\(i).txt", "w")
    }
}

exit(waitOnSelect())
