//
//  GitCommitRule.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

import Foundation
import Yams

private let AsciiPunctuationPattern = NSRegularExpression.escapedPattern(for: "`~!@#$%^&*()_+-=\\{}|;':\",./<>?") + "\\[\\]"
private let UnicodePunctuationPattern = NSRegularExpression.escapedPattern(for: "·~！@#￥%……&*（）——+-=【】、；‘：“，。、《》？")
private let PunctuationPattern = AsciiPunctuationPattern + UnicodePunctuationPattern
private let RegexOptions: NSRegularExpression.Options = [
    .anchorsMatchLines,
    .caseInsensitive
]

public struct GitCommitRule: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case types
        case scope
        case isEnabled = "enabled"
        case ignoringPattern = "ignoring-pattern"
        case ignoresHashAnchoredLines = "ignores-hash-anchored-lines"
        case allowsReverting = "allows-revert"
        case ignoresTrailingNewLines = "ignores-trailing-new-lines"
    }
    
    public struct Scope: Decodable {
        
        enum CodingKeys: String, CodingKey {
            case isRequired = "required"
            case allowsAsciiPunctuation = "allows-ascii-punctuation"
        }
        
        public let isRequired: Bool
        public let allowsAsciiPunctuation: Bool?
    }
    
    /// The types of the commit header. Default would be all values in `GitCommitType.all`.
    public let types: [String]
    /// The scope of the commit header. Default is:
    /// - scope:
    ///   - isRequired: false
    public let scope: Scope
    /// Indicates the git-commit is enabled or disabled. Default would be `true`.
    public var isEnabled: Bool
    /// The regex pattern to ignore with. Default is nil.
    public let ignoringPattern: String?
    /// Should ignore the `#` hash anchor beginning lines. Default is `false`.
    public let ignoresHashAnchoredLines: Bool
    /// Should allows revert commit. Default is `true`.
    public let allowsReverting: Bool
    /// Indicates ignores the triling new lines and trimming the trailing new lines when linting. Default is `false`.
    public let ignoresTrailingNewLines: Bool
    
    public init(
        at path: String) throws
    {
        guard FileManager.default.fileExists(atPath: path) else {
            throw GitCommitError.invalidConfigPath
        }
        
        let pathUrl = URL(fileURLWithPath: path)
        let file = try FileHandle(forReadingFrom: pathUrl)
        defer {
            file.closeFile()
        }
        
        let data = file.readDataToEndOfFile()
        guard !data.isEmpty, let config = String(data: data, encoding: .utf8)  else {
            throw GitCommitError.emptyConfigContents(atPath: path)
        }
        
        self = try YAMLDecoder().decode(
            type(of: self),
            from: config
        )
    }
    
    public init(
        from decoder: Decoder) throws
    {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let types = try container.decodeIfPresent([String].self, forKey: .types)
        let scope = try container.decodeIfPresent(Scope.self, forKey: .scope)
        let isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        let ignoringPattern = try container.decodeIfPresent(String.self, forKey: .ignoringPattern)
        let ignoresHashAnchoredLines = try container.decodeIfPresent(Bool.self, forKey: .ignoresHashAnchoredLines)
        let allowsReverting = try container.decodeIfPresent(Bool.self, forKey: .allowsReverting)
        let ignoresTrailingNewLines = try container.decodeIfPresent(Bool.self, forKey: .ignoresTrailingNewLines)
        
        self.init(
            types: types,
            scope: scope,
            isEnabled: isEnabled,
            ignoringPattern: ignoringPattern,
            ignoresHashAnchoredLines: ignoresHashAnchoredLines,
            allowsReverting: allowsReverting,
            ignoresTrailingNewLines: ignoresTrailingNewLines
        )
    }
    
    public init(
        types: [String]? = nil,
        scope: Scope? = nil,
        isEnabled: Bool = true,
        ignoringPattern: String? = nil,
        ignoresHashAnchoredLines: Bool? = nil,
        allowsReverting: Bool? = nil,
        ignoresTrailingNewLines: Bool? = nil)
    {
        self.types = types ?? GitCommitType.all.map { $0.rawValue }
        self.scope = scope ?? Scope(isRequired: false, allowsAsciiPunctuation: false)
        self.isEnabled = isEnabled
        self.ignoringPattern = ignoringPattern
        self.ignoresHashAnchoredLines = ignoresHashAnchoredLines ?? false
        self.allowsReverting = allowsReverting ?? true
        self.ignoresTrailingNewLines = ignoresTrailingNewLines ?? false
    }
}

extension GitCommitRule {
    
    public static var current: GitCommitRule {
        return (try? GitCommitRule(
            at: FileManager.default.currentDirectoryPath + "/.git-commit.yml"
        )) ?? GitCommitRule()
    }
}

extension GitCommitRule: GitCommitRuleRepresentable {
    
    public var debugDescription: String {
        return """
        <type>(<scope>): <subject> | (\(types.joined(separator: "|"))(SomeScope): This is a commit message.
        <BLANK LINE>               |
        <body>                     | <Optional>: This is a commit body.
        <BLANK LINE>               |
        <footer>                   | <(BREAKING CHANGE: isolate scope bindings definition has changed.)|(Closes #123, #245, #992)>
        
        Seek for more? Click -> https://docs.google.com/document/d/1QrDFcIiPjSLDn3EL15IJygNPiHORgU1_OOAqWjiDU5Y/edit
        """
    }
    
    public func map(
        commits: String) -> String
    {
        var commits = commits
        
        if ignoresHashAnchoredLines {
            commits = commits.components(separatedBy: CharacterSet.newlines)
                .filter { !$0.hasPrefix("#") }
                .joined(separator: "\n")
        }
        
        if ignoresTrailingNewLines {
            commits = trimming(
                charactersIn: .newlines,
                of: commits
            )
        }
        
        return commits
    }
    
    public func isEnabled(
        for commits: String) -> Bool
    {
        if
            let ignoring = ignoringPattern,
            let ignoringRegex = try? NSRegularExpression(pattern: ignoring, options: RegexOptions)
        {
            let range = (commits as NSString).range(of: commits)
            let matchs = ignoringRegex.matches(
                in: commits,
                options: [
                    .anchored
                ],
                range: range
            )
            
            if matchs.count == 1, case let match? = matchs.last, match.range == range {
                return false
            }
        }
        
        return isEnabled
    }
    
    public func asRegex() throws -> NSRegularExpression {
        
        guard isEnabled else {
            return try NSRegularExpression(
                pattern: "^[\\s.]*$",
                options: RegexOptions
            )
        }
        
        let availableCommitTypes = types.joined(separator: "|")
        
        let asciiPunc = AsciiPunctuationPattern
        let unicodePunc = UnicodePunctuationPattern
        let punctuation = asciiPunc + unicodePunc
        
        let contentsWithoutPunc = "[\u{4E00}-\u{9FA5}A-Za-z0-9_]"
        let contentsWithAsciiPunc = "[A-Za-z0-9\(asciiPunc) \\t]"
        let contentsWithoutReturn = "[\u{4E00}-\u{9FA5}A-Za-z0-9\(punctuation) \\t]"
        
        let scopeControl = self.scope.isRequired ? "" : "?"
        let typesControl = availableCommitTypes.isEmpty ? "" : ": "
        
        let scope = "\\(\(self.scope.allowsAsciiPunctuation ?? false ? contentsWithAsciiPunc : contentsWithoutPunc)+\\)"
        let subject = "\(contentsWithoutReturn)+"
        let header = "(\(availableCommitTypes))(\(scope))\(scopeControl)\(typesControl)(\(subject))"
        
        let body = "((\\n{1,2}\(contentsWithoutReturn)+)+)?"
        
        let breakingChange = "(BREAKING CHANGE: (\\n{0,2}\(contentsWithoutReturn))+)"
        let closingIssue = "(Closes \(contentsWithAsciiPunc)+)"
        let footer = "(\\n{2}(\(breakingChange)|\(closingIssue)))?"
        
        let revert = allowsReverting ? "revert: \(header)\\n{2}This reverts commit [A-Za-z0-9\(asciiPunc)]+" : ""
        let commit = "\(header)\(body)\(footer)"
        
        let pattern = "^(\(revert)|\(commit))$"
        
        return try NSRegularExpression(
            pattern: pattern,
            options: RegexOptions
        )
    }
}
