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
    
    /// Indicates the range is invalid.
    case invalidRange
    
    /// Indicates the git repository is not existing.
    case gitRepositoryNotExist(atPath: String)
    /// Indicates the git repository is invalid.
    case invalidGitRepository(atPath: String)
    /// Indicates the bootstrap is duplicate.
    case duplicateBootstrap
}

// MARK: - CustomStringConvertible

extension GitCommitError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidCommitPath:
            return "The commit contents' path is invalid."
        case .emptyCommitContents(atPath: let path):
            return "The contents of commit at \(path) is empty."
        case .invalidConfigPath:
            return "The configuration's path is invalid."
        case .emptyConfigContents(atPath: let path):
            return "The contents of configuration at \(path) is empty."
        case .invalidRange:
            return "The range is invalid."
        case .gitRepositoryNotExist(atPath: let path):
            return "The git repository at \(path) is not existing."
        case .invalidGitRepository(atPath: let path):
            return "The git reposotory at \(path) is invalid."
        case .duplicateBootstrap:
            return "Duplicate bootstrapping will be ignored."
        }
    }
}
