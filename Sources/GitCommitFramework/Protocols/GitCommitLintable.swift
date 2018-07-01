//
//  GitCommitLintable.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

import Foundation

// MARK: - GitCommitLintable.

public protocol GitCommitLintable {
    associatedtype Rule: GitCommitRuleRepresentable = GitCommitRule
    
    var commits: String { get }
    
    func lint(with rule: Rule, options: GitCommitLintOptions) throws -> Bool
}

extension GitCommitLintable {
    @discardableResult
    public func lint(with rule: Rule, options: GitCommitLintOptions = []) throws -> Bool {
        guard rule.isEnabled else {
            return true
        }
        
        let regex = try rule.asRegex()
        
        let range = (commits as NSString).range(of: commits)
        let matches = regex.matches(in: commits, options: [.anchored], range: range)
        
        let verbose = options.contains(GitCommitLintOptions.verbose)
        
        if verbose {
            echo(message: matches.count)
            matches.forEach { echo(message: (commits as NSString).substring(with: $0.range)) }
        }
        
        guard matches.startIndex == matches.index(before: matches.endIndex)
            , case let match? = matches.last
            , match.range == range
        else {
            echo(.error, message:
            """
            
            Commit message:
            ------------------------
            \(commits)
            ------------------------
            did not pass validate!!!
            """)
            echo(.warning, message:
            """

            -------------------------------------------
            Please check and follow the commit pattern:
            -------------------------------------------
            """)
            echo(.notes, message: "\n\(CommitFormater)\n")
            return false
        }
        
        if verbose {
            echo(.notes, message: "\nCommit message: \n```\n\(commits)\n```\npassed!!!")
        }
        
        return true
    }
}
