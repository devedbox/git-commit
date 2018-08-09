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
    
    static var allTests = [
        ("testVersion", testVersion),
        ("testTrimmingEmptyString", testTrimmingEmptyString),
        ("testReadFromFile", testReadFromFile),
        ("testCommits2String", testCommits2String),
        ("testInvalidCommitsPath", testInvalidCommitsPath),
        ("testEmptyCommits", testEmptyCommits),
        ("testNonEmptyCommits", testNonEmptyCommits),
        ("testLintSimpleFeatureCommits", testLintSimpleFeatureCommits),
        ("testRevertCommit", testRevertCommit),
        ("testLintHeaderAndBody", testLintHeaderAndBody),
        ("testLintHeaderAndFooter", testLintHeaderAndFooter),
        ("testLintHeaderAndBodyAndFooter", testLintHeaderAndBodyAndFooter),
    ]
    
    let rule = GitCommitRule()
    let trimmingRule = GitCommitRule(ignoresTrailingNewLines: true)
    let anchoredRule = GitCommitRule(ignoresHashAnchoredLines: true)
    let trimmingAnchoredRule = GitCommitRule(ignoresHashAnchoredLines: true, ignoresTrailingNewLines: true)
    
    func testBootstrap() {
        do {
            try GitCommit.bootstrap()
        } catch GitCommitError.gitRepositoryNotExist(atPath: _) {
            XCTAssertTrue(true)
        } catch let error {
            XCTAssertFalse(error.localizedDescription.isEmpty)
            XCTAssertTrue(true)
        }
    }
    
    func testVersion() {
        XCTAssertEqual(GitCommitVersion, GitCommit.version)
    }
    
    func testTrimmingEmptyString() {
        let string = ""
        XCTAssertEqual(string, trimming(charactersIn: .newlines, of: string))
    }
    
    func testReadFromFile() {
        let path = FileManager.default.currentDirectoryPath + "/commits"
        defer {
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        var commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        """
        
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path,
                                           contents: commits.data(using: .utf8),
                                           attributes: nil)
        }
        
        XCTAssertTrue(try GitCommit(commitPath: "commits").lint(with: rule))
        
        if FileManager.default.fileExists(atPath: path) {
            try? FileManager.default.removeItem(atPath: path)
        }
        
        commits = """
        test(Ignores): Test disable ignores-hash-anchored-lines.
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #\tmodified:   .git-commit.yml
        #\tmodified:   GitCommit.xcodeproj/project.xcworkspace/xcuserdata/devedbox.xcuserdatad/UserInterfaceState.xcuserstate
        #
        """
        
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path,
                                           contents: commits.data(using: .utf8),
                                           attributes: nil)
        }
        XCTAssertTrue(try GitCommit(commitPath: "commits").lint(with: rule))
        XCTAssertFalse(try GitCommit(commitPath: "commits").lint(with: anchoredRule))
        XCTAssertTrue(try GitCommit(commitPath: "commits").lint(with: trimmingRule))
        XCTAssertTrue(try GitCommit(commitPath: "commits").lint(with: trimmingAnchoredRule))
        
        let ignoresHashAnchoredLinesRule = GitCommitRule(types: nil, scope: nil, isEnabled: true, ignoringPattern: nil, ignoresHashAnchoredLines: true, allowsReverting: true)
        XCTAssertFalse(try GitCommit(commitPath: "commits").lint(with: ignoresHashAnchoredLinesRule))
        
        let ignoresTrailingNewLinesRule = GitCommitRule(types: nil, scope: nil, isEnabled: true, ignoringPattern: nil, ignoresHashAnchoredLines: true, allowsReverting: true, ignoresTrailingNewLines: true)
        XCTAssertTrue(try GitCommit(commitPath: "commits").lint(with: ignoresTrailingNewLinesRule))
    }
    
    func testCommits2String() {
        let commits = "This is a commit message."
        XCTAssertEqual(commits, GitCommit(stringLiteral: commits).description)
    }
    
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
            _ = try GitCommit(commitPath: "emptyCommits")
        } catch GitCommitError.emptyCommitContents(atPath: _) {
            XCTAssertTrue(true)
        } catch _ {
            XCTAssertFalse(false)
        }
    }
    
    func testNonEmptyCommits() {
        let path = FileManager.default.currentDirectoryPath + "/nonEmptyCommits"
        defer {
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path,
                                           contents:
                                                    """
                                                    This is a commit message.
                                                    """.data(using: .utf8),
                                           attributes: nil)
        }
        
        do {
            _ = try GitCommit(commitPath: "nonEmptyCommits")
        } catch GitCommitError.emptyCommitContents(atPath: _) {
            XCTAssertFalse(true)
        } catch let error {
            print(error)
            XCTAssertFalse(true)
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
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        """
        
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: anchoredRule, options: options))
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: trimmingRule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
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
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingRule, options: options))
        
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
        
        let nonAllowsRevertingRule = GitCommitRule(allowsReverting: false)
        commits =
        """
        revert: feat(pencil): add 'graphiteWidth' option
        
        This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: nonAllowsRevertingRule, options: options))
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
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        """
        
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: anchoredRule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
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
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
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
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        """
        
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: anchoredRule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingRule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        
        
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingRule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        
        
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
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
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
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
        
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: anchoredRule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
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
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingRule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        BREAKING CHANGE: isolate scope bindings definition has changed.
        
        To migrate the code follow the example below:
        
        Before:
        
        sample1
        
        After:
        
        sample2
        
        The removed `inject` wasn't generaly useful for directives so there should be no code using it.
        
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        
        
        
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
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
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        
        """
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule, options: options))
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingAnchoredRule, options: options))
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
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: trimmingRule, options: options))
        
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
}
