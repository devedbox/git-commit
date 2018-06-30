//
//  misc.swift
//  Commit
//
//  Created by devedbox on 2018/6/29.
//

import Foundation

let ESC = "\u{001B}"

/// The format of the commit message.
let CommitFormater = """
                    <type>(<scope>): <subject>
                    <BLANK LINE>
                    <body>
                    <BLANK LINE>
                    <footer>
                    """

/// The severity level of the logs.
public enum Severity {
    case `default`
    case error
    case warning
    case notes
    
    func value(for contents: String) -> String {
        switch self {
        case .default:
            return "\(ESC)[;1m\(contents)\(ESC)[0m"
        case .error:
            return "\(ESC)[31;1m\(contents)\(ESC)[0m"
        case .notes:
            return "\(ESC)[32;1m\(contents)\(ESC)[0m"
        case .warning:
            return "\(ESC)[33;1m\(contents)\(ESC)[0m"
        }
    }
}

/// Echos message to the console using the given value of `Severity`.
public func echo(_ severity: Severity = .default, message: @autoclosure () -> Any) { print(severity.value(for: "\(message())")) }
