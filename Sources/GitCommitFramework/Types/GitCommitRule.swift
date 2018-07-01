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

public struct GitCommitRule: Decodable {
    
    enum CodingKeys: String, CodingKey {
        case types
        case scope
        case isEnabled = "enabled"
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
    public let isEnabled: Bool
    
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
        let isEnabled = try container.decodeIfPresent(Bool.self, forKey: CodingKeys.isEnabled)
        
        self.init(types: types, scope: scope, isEnabled: isEnabled)
    }
    
    public init(types: [String]? = nil, scope: Scope? = nil, isEnabled: Bool? = nil) {
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
        
        self.isEnabled = isEnabled ?? true
    }
}

extension GitCommitRule {
    
    public static var current: GitCommitRule {
        return (try? GitCommitRule(at: FileManager.default.currentDirectoryPath + "/.git-commit.yml")) ?? GitCommitRule()
    }
}

extension GitCommitRule: GitCommitRuleRepresentable {
    
    public func asRegex() throws -> NSRegularExpression {
        guard isEnabled else {
            return try NSRegularExpression(pattern: "^[\\s.]*$", options: [.anchorsMatchLines, .caseInsensitive])
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
        
        return try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .caseInsensitive])
    }
}
