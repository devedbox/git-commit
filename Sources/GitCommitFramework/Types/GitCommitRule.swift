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
private let RegexOptions: NSRegularExpression.Options = [.anchorsMatchLines, .caseInsensitive]

public struct GitCommitRule: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case types
        case scope
        case isEnabled = "enabled"
        case ignoringPattern = "ignoring-pattern"
    }
    
    public struct Scope: Decodable {
        
        enum CodingKeys: String, CodingKey {
            case isRequired = "required"
            case allowsAsciiPunctuation = "allows-ascii-punctuation"
        }
        
        public let isRequired: Bool
        public let allowsAsciiPunctuation: Bool?
    }
    
    public let types: [String]!
    public let scope: Scope!
    public var isEnabled: Bool
    public let ignoringPattern: String?
    
    public init(at path: String) throws {
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
        
        self = try YAMLDecoder().decode(type(of: self), from: config)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let types = try container.decodeIfPresent([String].self, forKey: CodingKeys.types)
        let scope = try container.decodeIfPresent(Scope.self, forKey: CodingKeys.scope)
        let isEnabled = try container.decode(Bool.self, forKey: CodingKeys.isEnabled)
        let ignoringPattern = try container.decodeIfPresent(String.self, forKey: CodingKeys.ignoringPattern)
        
        self.init(types: types, scope: scope, isEnabled: isEnabled, ignoringPattern: ignoringPattern)
    }
    
    public init(types: [String]? = nil, scope: Scope? = nil, isEnabled: Bool = true, ignoringPattern: String? = nil) {
        if let types = types {
            self.types = types
        } else {
            self.types = GitCommitType.all.map { $0.rawValue }
        }
        
        if let scope = scope {
            self.scope = scope
        } else {
            self.scope = Scope(isRequired: false, allowsAsciiPunctuation: false)
        }
        
        self.isEnabled = isEnabled
        self.ignoringPattern = ignoringPattern
    }
}

extension GitCommitRule {
    
    public static var current: GitCommitRule {
        return (try? GitCommitRule(at: FileManager.default.currentDirectoryPath + "/.git-commit.yml")) ?? GitCommitRule()
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
    
    public func isEnabled(for commits: String) -> Bool {
        
        if let ignoring = ignoringPattern, let ignoringRegex = try? NSRegularExpression(pattern: ignoring, options: RegexOptions) {
            
            let range = (commits as NSString).range(of: commits)
            let matchs = ignoringRegex.matches(in: commits,
                                               options: [.anchored],
                                               range: range)
            
            if matchs.count == 1, case let match? = matchs.last, match.range == range {
                return false
            }
        }
        
        return isEnabled
    }
    
    public func asRegex() throws -> NSRegularExpression {
        
        guard isEnabled else {
            return try NSRegularExpression(pattern: "^[\\s.]*$", options: RegexOptions)
        }
        
        let availableCommitTypes = types.joined(separator: "|")
        
        let asciiPunc = AsciiPunctuationPattern
        let unicodePunc = UnicodePunctuationPattern
        let punctuation = asciiPunc + unicodePunc
        
        let contentsWithoutPunc = "[\u{4E00}-\u{9FA5}A-Za-z0-9_]"
        let contentsWithAsciiPunc = "[A-Za-z0-9\(asciiPunc) ]"
        let contentsWithoutReturn = "[\u{4E00}-\u{9FA5}A-Za-z0-9\(punctuation) ]"
        let contentsWithReturn = "[\\n" + contentsWithoutReturn[contentsWithoutReturn.index(after: contentsWithoutReturn.startIndex)...]
        
        let scopeControl = self.scope.isRequired ? "" : "?"
        let typesControl = availableCommitTypes.isEmpty ? "" : ": "
        
        let scope = "\\(\(self.scope.allowsAsciiPunctuation ?? false ? contentsWithAsciiPunc : contentsWithoutPunc)+\\)"
        let subject = "\(contentsWithoutReturn)+"
        let header = "(\(availableCommitTypes))(\(scope))\(scopeControl)\(typesControl)(\(subject))"
        
        let body = "((\\n{1,2}\(contentsWithoutReturn)+)+)?"
        
        let breakingChange = "(BREAKING CHANGE: \(contentsWithReturn)+)"
        let closingIssue = "(Closes \(contentsWithAsciiPunc)+)"
        let footer = "(\\n\\n(\(breakingChange)|\(closingIssue)))?"
        
        let revert = "revert: \(header)\\n{2}This reverts commit [A-Za-z0-9\(asciiPunc)]+"
        let commit = "\(header)\(body)\(footer)"
        
        let pattern = "^(\(revert)|\(commit))$"
        
        return try NSRegularExpression(pattern: pattern, options: RegexOptions)
    }
}
