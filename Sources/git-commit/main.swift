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

let command = CommandLine.arguments[1]
switch command {
case "version": // Shows the version info.
    echo(.notes, message: GitCommit.version)
case "init": // Bootstrap.
    do {
        try GitCommit.bootstrap()
    } catch _ {
    }
default:
    do {
        guard try GitCommit(commitPath: CommandLine.arguments[1]).lint(with: .current) else {
            exit(1)
        }
    } catch GitCommitError.emptyCommitContents(atPath: let path) {
        echo(.warning, message:
            """
            There is no commits content at '\(path)'
            """)
        exit(1)
    } catch _ {
        exit(1)
    }
}

exit(0)
