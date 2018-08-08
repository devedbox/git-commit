//
//  misc.swift
//  git-commit
//
//  Created by devedbox on 2018/8/8.
//

import Foundation
import GitCommitFramework

/// The constant help message.
internal var HelpMessage = """
Available commands:

help            : Shows help message.
version         : Shows the version of git-commit.
init[--override]: Creates hooks and config files at the project path.
PATH            : Specify the commit message path to lint.
"""
/// Notify extra invalid arguments if needed.
internal func notifyArgumentsErrorIfNeeded(args: [String]) {
    guard !args.isEmpty else {
        return
    }
    
    echo(.error, message: """
        Invalid commands or options: \(args.joined(separator: " "))
        
        \(HelpMessage)
        """)
    exit(1)
}
