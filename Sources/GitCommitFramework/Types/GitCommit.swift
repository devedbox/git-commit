//
//  GitCommit.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

import Foundation

// MARK: - GitCommit.

public struct GitCommit: GitCommitLintable {
    /// The commits contents.
    private let _commits: String
    /// Returns the commit contents of the receiver of `GitCommit`.
    public var commits: String { return _commits }
    
    /// Creates an instance of `GitCommit` with the given commit path.
    public init(commitPath: String, isAbsolutePath: Bool = false) throws {
        let path = (isAbsolutePath ? "" : FileManager.default.currentDirectoryPath + "/") + commitPath
        
        guard FileManager.default.fileExists(atPath: path) else {
            throw GitCommitError.invalidCommitPath
        }
        
        let commitPathUrl = URL(fileURLWithPath: commitPath)
        
        let file = try FileHandle(forReadingFrom: commitPathUrl)
        defer {
            file.closeFile()
        }
        
        guard var commits = String(data: file.availableData, encoding: .utf8)
            , !commits.isEmpty
        else {
            throw GitCommitError.emptyCommitContents(atPath: path)
        }
        
        _ = commits.hasSuffix("\n") ? commits.removeLast() : nil
        
        self._commits = commits
    }
}

// MARK: - ExpressibleByStringLiteral.

extension GitCommit: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: StringLiteralType) {
        _commits = value
    }
}

// MARK: - CustomStringConvertible.

extension GitCommit: CustomStringConvertible {
    public var description: String {
        return commits
    }
}
