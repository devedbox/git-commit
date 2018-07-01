//
//  GitCommitTests.swift
//  GitCommitTests
//
//  Created by devedbox on 2018/7/1.
//

import XCTest
import Foundation
@testable import GitCommitFramework

final class GitCommitTests: XCTestCase {
    
    let rule = GitCommitRule()
    
    func testInvalidCommitsPath() {
        do {
            _ = try GitCommit(commitPath: "invalid")
        } catch GitCommitError.invalidCommitPath {
            XCTAssertTrue(true)
        } catch _ {
            XCTAssertFalse(false)
        }
    }
    
    func testEmptyCommits() {
        let path = FileManager.default.currentDirectoryPath + "/emptyCommits"
        defer {
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path,
                                           contents: nil,
                                           attributes: nil)
        }
        
        do {
            _ = try GitCommit(commitPath: path)
        } catch GitCommitError.emptyCommitContents(atPath: _) {
            XCTAssertTrue(true)
        } catch _ {
            XCTAssertFalse(false)
        }
    }
    
    func testLintSimpleFeatureCommits() {
        let options: GitCommitLintOptions = [.verbose]
        var commits: GitCommit = ""
        
        let asciiCommits = "This is a commit message."
        let unicodeCommits = "这是一条提交信息。"
        
        let asciiScope = "SomeScope"
        let unicudeScope = "提交域"
        
        func runTest(for scope: String, with targetCommits: String) {
            commits = GitCommit(stringLiteral: "feat(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "fix(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "docs(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "style(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "refactor(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "test(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "chore(\(scope)): \(targetCommits)")
            XCTAssertTrue(try commits.lint(with: rule, options: options))
            
            commits = GitCommit(stringLiteral: "fea(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "fixs(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "doc(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "styling(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "refacte(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "testing(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
            commits = GitCommit(stringLiteral: "choring(\(scope)): \(targetCommits)")
            XCTAssertFalse(try commits.lint(with: rule, options: options))
        }
        
        runTest(for: asciiScope, with: asciiCommits)
        runTest(for: unicudeScope, with: asciiCommits)
        runTest(for: asciiScope, with: unicodeCommits)
        runTest(for: unicudeScope, with: unicodeCommits)
        runTest(for: asciiScope + unicudeScope,
                with: asciiCommits + unicodeCommits)
    }
    
    func testRevertCommit() {
        let options: GitCommitLintOptions = [.verbose]
        var commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option

        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        """
        
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option
        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option
        
        
        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option

        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option
        
        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        The second part.
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option
        
        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        
        The second part.
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
    }
    
    func testLintHeaderAndBody() {
        let options: GitCommitLintOptions = [.verbose]
        var commits = ""
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        """
        
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        
        The first line of specific message.
        The second line of specific message.
        """
        
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        
        The second line of specific message.
        """
        
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        
        
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
    }
    
    func testLintHeaderAndFooter() {
        let options: GitCommitLintOptions = [.verbose]
        var commits = ""
        
        commits = """
        feat(SomeFeature): This is a message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        To migrate the code follow the example below:
        Before:
        sample1
        After:
        sample2
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        
        To migrate the code follow the example below:
        
        Before:
        
        sample1
        
        After:
        
        sample2
        
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        
        To migrate the code follow the example below:
        
        Before:
        
        sample1
        
        After:
        
        sample2
        
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        
        
        
        
        
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
    }
    
    func testLintHeaderAndBodyAndFooter() {
        let options: GitCommitLintOptions = [.verbose]
        var commits = ""
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        To migrate the code follow the example below:
        Before:
        sample1
        After:
        sample2
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        
        To migrate the code follow the example below:
        
        Before:
        
        sample1
        
        After:
        
        sample2
        
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        
        To migrate the code follow the example below:
        
        Before:
        
        sample1
        
        After:
        
        sample2
        
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        
        
        
        
        
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        Closes #8989, #3131, #issue3, &issue4
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
    }

    static var allTests = [
        ("testInvalidCommitsPath", testInvalidCommitsPath),
        ("testEmptyCommits", testEmptyCommits),
        ("testLintSimpleFeatureCommits", testLintSimpleFeatureCommits),
        ("testRevertCommit", testRevertCommit),
        ("testLintHeaderAndBody", testLintHeaderAndBody),
        ("testLintHeaderAndFooter", testLintHeaderAndFooter),
        ("testLintHeaderAndBodyAndFooter", testLintHeaderAndBodyAndFooter),
    ]
}
