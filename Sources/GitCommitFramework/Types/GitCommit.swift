//
//  GitCommit.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

import Foundation

// MARK: - GitCommit.

public struct GitCommit: GitCommitLintable {
    /// Returns the version of the framework.
    public static var version: String { return GitCommitVersion }
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

// MARK: - Bootstrap.

extension GitCommit {
    ///
    public static func bootstrap() throws {
        let cwd = FileManager.default.currentDirectoryPath
        let commitMsgHookContent = """
        #!/bin/sh
        
        git-commit $1
        """
        
        var isDirectory: ObjCBool = true
        let isFileExisting: Bool = FileManager.default.fileExists(atPath: cwd + "/.git", isDirectory: &isDirectory)
        
        guard isFileExisting else {
            throw GitCommitError.gitRepositoryNotExist(atPath: cwd)
        }
        guard isDirectory.boolValue else {
            throw GitCommitError.invalidGitRepository(atPath: cwd + "/.git")
        }
        
        let commitMsgHookPath = cwd + "/.git/hooks/commit-msg"
        if FileManager.default.fileExists(atPath: commitMsgHookPath), case let commitMsgHook? = try? String(contentsOfFile: commitMsgHookPath), commitMsgHook == commitMsgHookContent {
            throw GitCommitError.duplicateBootstrap
        }
        
        try? FileManager.default.removeItem(atPath: commitMsgHookPath)
        if !FileManager.default.fileExists(atPath: cwd + "/.git/hooks") {
            try? FileManager.default.createDirectory(atPath: cwd + "/.git/hooks", withIntermediateDirectories: false, attributes: nil)
        }
        FileManager.default.createFile(atPath: commitMsgHookPath,
                                       contents: commitMsgHookContent.data(using: .utf8),
                                       attributes: [.posixPermissions: 493])
        
        let configPath = cwd + "/.git-commit.yml"
        if !FileManager.default.fileExists(atPath: configPath) {
            let config =
            """
            enabled: true
            # types: # defaults using (feat|fix|docs|style|refactor|test|chore) types.
            scope:
              required: false
              allows-ascii-punctuation: true
            # ignoring-pattern: # Default is nil.
            # ignores-hash-anchored-lines: true # Default is false.
            # allowsReverting: true # Default is true.
            # ignores-trailing-new-lines: true # Default is false.
            """
            FileManager.default.createFile(atPath: configPath,
                                           contents: config.data(using: .utf8),
                                           attributes: nil)
        }
    }
}
