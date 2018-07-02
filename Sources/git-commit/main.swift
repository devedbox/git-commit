//
//  main.swift
//  git-commit
//
//  Created by devedbox.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import GitCommitFramework

guard CommandLine.arguments.count >= 2 else {
    echo(.warning, message: "\nInvalid count of arguments.\n")
    exit(1)
}

do {
    guard try GitCommit(commitPath: CommandLine.arguments[1]).lint(with: .current) else {
        exit(1)
    }
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
