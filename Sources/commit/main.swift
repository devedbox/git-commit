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

let commit_msg_path = CommandLine.arguments[1]
let commit_msg_path_url = URL(fileURLWithPath: FileManager.default.currentDirectoryPath + "/" + commit_msg_path)
var commit_msg = try String(contentsOf: commit_msg_path_url)

guard !commit_msg.isEmpty else {
    exit(1)
}

try lint(commit_msg)

exit(0)
