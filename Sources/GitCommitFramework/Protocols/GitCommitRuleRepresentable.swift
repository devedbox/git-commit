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

public protocol GitCommitRuleRepresentable: RegularExpressionConvertible {
    var isEnabled: Bool { get }
}
