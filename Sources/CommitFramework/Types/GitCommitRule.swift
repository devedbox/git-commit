//
//  GitCommitRule.swift
//  CommitFramework
//
//  Created by devedbox on 2018/6/30.
//

import Foundation

public struct GitCommitRule: GitCommitRuleRepresentable {
    
    public init() { }
    
    public func asRegex() throws -> NSRegularExpression {
        let availableCommitTypes = GitCommitType.all.map { $0.rawValue }.joined(separator: "|")
        
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
        
        return try NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines, .caseInsensitive])
    }
}
