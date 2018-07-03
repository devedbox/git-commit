//
//  GitCommitRuleRepresentable.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

import Foundation

// MARK: - RegularExpressionConvertible.

public protocol RegularExpressionConvertible {
    associatedtype RegularExpression: NSRegularExpression = NSRegularExpression
    
    func asRegex() throws -> RegularExpression
}

extension RegularExpressionConvertible {
    public var regex: RegularExpression? {
        return try? asRegex()
    }
}

// MARK: - GitCommitRuleRepresentable.

public protocol GitCommitRuleRepresentable: RegularExpressionConvertible, CustomDebugStringConvertible {
    var isEnabled: Bool { get }
    
    func map(commits: String) -> String
    
    func isEnabled(for commits: String) -> Bool
}

extension GitCommitRuleRepresentable {
    
    public func map(commits: String) -> String {
        return commits
    }
    
    public func isEnabled(for commits: String) -> Bool {
        return isEnabled
    }
}
