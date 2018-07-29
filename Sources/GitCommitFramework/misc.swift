//
//  misc.swift
//  GitCommitFramework
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

/// Trimming characters with the given character set of the given string.
public func trimming(charactersIn characterSet: CharacterSet, of string: String) -> String {
    guard !string.isEmpty else {
        return string
    }
    
    var string = string
    var index = string.index(before: string.endIndex)
    while index >= string.startIndex, characterSet.isSuperset(of: CharacterSet(charactersIn: String(string[index]))) {
        string.remove(at: index)
        string.formIndex(before: &index)
    }
    
    return string
}
