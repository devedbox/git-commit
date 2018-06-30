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

import CommitFramework

guard CommandLine.arguments.count >= 2 else {
    echo(.warning, message: "\nThere is no commits.\n")
    exit(1)
}

do {
    try GitCommit(commitPath: CommandLine.arguments[1]).lint(with: GitCommitRule())
} catch let error {
    switch error {
    case GitCommitError.emptyCommitContents(atPath: let path):
        echo(.warning, message:
            """
            There is no commits content at '\(path)'
            """)
    default:
        break
    }
    
    exit(1)
}

exit(0)
