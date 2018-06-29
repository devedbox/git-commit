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

/// Values of commit type.
public enum CommitType: String {
    case feature = "feat" // New feature.
    case fix = "fix" // Bug fix.
    case docs = "docs" // Documentation.
    case style = "style" // Style of codes, formatting, missing semo colons, ...
    case refactor = "refactor" // Refactor of codes.
    case test = "test" // Testing codes.
    case chore = "chore" // Maintain.
    
    /// Returns all of the cases.
    internal static var all: [CommitType] {
        return [
            .feature,
            .fix,
            .docs,
            .style,
            .refactor,
            .test,
            .chore
        ]
    }
}

/// Echos message to the console using the given value of `Severity`.
public func echo(_ severity: Severity = .default, message: @autoclosure () -> Any) { print(severity.value(for: "\(message())")) }

/// Lint the commits messages.
@discardableResult
public func lint(_ commits: String, verbose: Bool = false) throws -> Bool {
    let availableCommitTypes = CommitType.all.map { $0.rawValue }.joined(separator: "|")
    
    let asciiPunc = NSRegularExpression.escapedPattern(for: "`~!@#$%^&*()_+-=\\{}|;':\",./<>?") + "\\[\\]"
    let unicodePunc = NSRegularExpression.escapedPattern(for: "·~！@#￥%……&*（）——+-=【】、；‘：“，。、《》？")
    let punctuation = asciiPunc + unicodePunc
    
    let contentsWithoutPunc = "[\u{4E00}-\u{9FA5}A-Za-z0-9_]"
    let contentsWithAsciiPunc = "[A-Za-z0-9\(asciiPunc) ]"
    let contentsWithoutReturn = "[\u{4E00}-\u{9FA5}A-Za-z0-9\(punctuation) ]"
    let contentsWithReturn = "[\\n" + contentsWithoutReturn[contentsWithoutReturn.index(after: contentsWithoutReturn.startIndex)...]
    
    let scope = "\\(\(contentsWithoutPunc)+\\)"
    let subject = "\(contentsWithoutReturn)+"
    let header = "(\(availableCommitTypes))(\(scope))*: (\(subject))"
    
    let body = "((\\n{1,2}\(contentsWithoutReturn)+)+)?"
    
    let breakingChange = "(BREAKING CHANGE: \(contentsWithReturn)+)"
    let closingIssue = "(Closes \(contentsWithAsciiPunc)+)"
    let footer = "(\\n\\n(\(breakingChange)|\(closingIssue)))?"
    
    let pattern = "^\(header)\(body)\(footer)$"
    
    verbose ? echo(message: pattern) : ()
    
    let range = (commits as NSString).range(of: commits)
    
    let regex = try NSRegularExpression(pattern: pattern,
                                        options: [.anchorsMatchLines, .caseInsensitive])
    let matches = regex.matches(in: commits, options: [.anchored],
                                range: range)
    
    if verbose {
        echo(message: matches.count)
        matches.forEach { echo(message: (commits as NSString).substring(with: $0.range)) }
    }
    
    guard matches.startIndex == matches.index(before: matches.endIndex)
        , case let match? = matches.last
        , match.range == range
        else {
            echo(.error, message: "\nCommit message: \n```\n\(commits)\n```\ndid not pass!!!")
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
