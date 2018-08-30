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

let commands = CommandLine.arguments
guard commands.count >= 2 else {
    echo(.warning, message: """
    Invalid commands specified.

    \(HelpMessage)
    """)
    exit(1)
}

let command = commands[1]
switch command {
case "help":
    notifyArgumentsErrorIfNeeded(args: Array(commands[2...]))
    echo(message: HelpMessage)
case "version": // Shows the version info.
    notifyArgumentsErrorIfNeeded(args: Array(commands[2...]))
    echo(message: GitCommit.version)
case "init": // Bootstrap.
    let allowsOverriding = commands.index(
        1,
        offsetBy: 1,
        limitedBy: commands.index(before: commands.endIndex)
    ).map { commands[$0] == "--override" } ?? false
    
    notifyArgumentsErrorIfNeeded(
        args: Array(commands[(allowsOverriding ? 3 : 2)...])
    )
    
    do {
        try GitCommit.bootstrap(allowsOverriding: allowsOverriding)
        echo(.notes, message: "Creates git hooks and .git-commit.yml configuration successfully.")
    } catch let error {
        switch error {
        case GitCommitError.gitRepositoryNotExist(atPath: _): fallthrough
        case GitCommitError.invalidGitRepository(atPath: _):
            echo(.error, message:
                """
                There is no valid git repository. Please create git repository by running `git init` first.
                """)
        case GitCommitError.duplicateBootstrap:
            echo(.warning, message:
                """
                \(GitCommitError.duplicateBootstrap) Using '--override' to override older one.
                """)
        default:
            break
        }
        exit(1)
    }
default:
    notifyArgumentsErrorIfNeeded(args: Array(commands[2...]))
    do {
        guard try GitCommit(commitPath: command).lint(with: .current) else {
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
