//
//  GitCommitType.swift
//  CommitFramework
//
//  Created by devedbox on 2018/6/30.
//

// MARK: - GitCommitType.

/// Values of commit type.
public enum GitCommitType: String {
    case feature = "feat" // New feature.
    case fix = "fix" // Bug fix.
    case docs = "docs" // Documentation.
    case style = "style" // Style of codes, formatting, missing semo colons, ...
    case refactor = "refactor" // Refactor of codes.
    case test = "test" // Testing codes.
    case chore = "chore" // Maintain.
    
    /// Returns all of the cases.
    internal static var all: [GitCommitType] {
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
