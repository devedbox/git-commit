//
//  GitCommitError.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

// MARK: - GitCommitError.

/// The error type of `GitCommit`.
public enum GitCommitError: Error {
    /// Indicates the path of the commit is invalid.
    case invalidCommitPath
    /// Indicates the commits content of the given path is empty.
    case emptyCommitContents(atPath: String)
    
    /// Indicates the path of the configuration is invalid.
    case invalidConfigPath
    /// Indicates the commits content of the given path is empty.
    case emptyConfigContents(atPath: String)
}
