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
echo(.warning, message: """
        Invalid commands specified.

        Available commands:

        version: Shows the version of git-commit.
        init: Creates hooks and config files at the project path.
        PATH: Specify the commit message path to lint.
        """)
guard CommandLine.arguments.count >= 2 else {
    echo(.warning, message: """
        Invalid commands specified.

        Available commands:

        version: Shows the version of git-commit.
        init: Creates hooks and config files at the project path.
        PATH: Specify the commit message path to lint.
        """)
    exit(1)
}

let command = CommandLine.arguments[1]
switch command {
case "version": // Shows the version info.
    echo(.notes, message: GitCommit.version)
case "init": // Bootstrap.
    do {
        try GitCommit.bootstrap()
        echo(.notes, message: "Creates git hooks and .git-commit.yml configuration successfully.")
    } catch let error {
        switch error {
        case GitCommitError.gitRepositoryNotExist(atPath: _): fallthrough
        case GitCommitError.invalidGitRepository(atPath: _):
            echo(.error, message:
                """
                There is no valid git repository. Please create git repository first by running `git init`.
                """)
        case GitCommitError.duplicateBootstrap:
            echo(.warning, message:
                """
                \(GitCommitError.duplicateBootstrap)
                """)
        default:
            break
        }
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
    } catch let error {
        echo(.error, message:
            """
            Error occurred during linting: \(error)
            """)
        exit(1)
    }
}

exit(0)
