//
// main.swift
// Commit
//
// Created by devedbox.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import Foundation
import CommitFramework

guard CommandLine.arguments.count >= 2 else {
    echo(.warning, message: "\nThere is no commits.\n")
    exit(1)
}

let commitsPath = CommandLine.arguments[1]
let commitsPathUrl = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + commitsPath)
let originalCommits = try String(contentsOf: commitsPathUrl)

let file = try FileHandle(forReadingFrom: commitsPathUrl)
defer {
    file.closeFile()
}

guard var commits = String(data: file.availableData, encoding: .utf8)
    , !commits.isEmpty
else {
    exit(1)
}

if commits.hasSuffix("\n") {
    commits.removeLast()
}

guard try lint(commits) else {
    exit(1)
}

exit(0)
