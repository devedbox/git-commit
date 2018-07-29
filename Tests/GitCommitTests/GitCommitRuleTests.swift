//
//  GitCommitRuleTests.swift
//  GitCommitTests
//
//  Created by devedbox on 2018/7/1.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import XCTest
import Foundation
import Yams
@testable import GitCommitFramework

internal struct TestIsEnabledGitCommitRule: GitCommitRuleRepresentable {
    var debugDescription: String {
        return ""
    }
    
    func asRegex() throws -> NSRegularExpression {
        return try NSRegularExpression(pattern: "", options: [])
    }
    
    internal var isEnabled: Bool
}

class GitCommitRuleTests: XCTestCase {
    static var allTests = [
        ("testDefaultTrippingHashAnchoredLines", testDefaultTrippingHashAnchoredLines),
        ("testTrippingHashAnchoredLines", testTrippingHashAnchoredLines),
        ("testRegex", testRegex),
        ("testDisable", testDisable),
        ("testIgnoringPattern", testIgnoringPattern),
        ("testInvalidConfigPath", testInvalidConfigPath),
        ("testEmptyConfigs", testEmptyConfigs),
        ("testReadConfigFile", testReadConfigFile),
        ("testRuleConfigurationFile", testRuleConfigurationFile),
        ("testTypes", testTypes),
        ("testScopeRequiredCase", testScopeRequiredCase),
        ("testIgnoresHashAnchoredLines", testIgnoresHashAnchoredLines),
        ("testDefaultIsEnabled", testDefaultIsEnabled),
    ]
    
    func testDefaultTrippingHashAnchoredLines() {
        let rule = TestIsEnabledGitCommitRule(isEnabled: true)
        
        let commits = """
        This is a commit message.
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #
        #
        """
        
        XCTAssertEqual(rule.map(commits: commits), commits)
    }
    
    func testTrippingHashAnchoredLines() {
        let rule = GitCommitRule(ignoresHashAnchoredLines: true)
        let commitsMsg = "feat: This is a commit message."
        let commitsMsgWithHash = "feat: This #is #a # #commit #message. #"
        
        var commits = """
        \(commitsMsg)
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #
        #
        """
        
        XCTAssertNotNil(rule.ignoresHashAnchoredLines)
        XCTAssertTrue(rule.ignoresHashAnchoredLines)
        
        XCTAssertEqual(rule.map(commits: commits), commitsMsg)
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        
        commits = """
        \(commitsMsgWithHash)
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #
        #
        """
        
        XCTAssertEqual(rule.map(commits: commits), commitsMsgWithHash)
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        
        commits = """
        # This is a commit message will be ignored.
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #
        #
        """
        
        XCTAssertTrue(rule.map(commits: commits).isEmpty)
        XCTAssertThrowsError(try GitCommit(stringLiteral: commits).lint(with: rule))
        
        commits = """
        \(commitsMsg)
        
        # This is a commit message will be ignored.
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #
        #
        """
        
        XCTAssertEqual(rule.map(commits: commits), commitsMsg + "\n")
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        
        commits = """
        \(commitsMsgWithHash)
        
        
        # This is a commit message will be ignored.
        # Please enter the commit message for your changes. Lines starting
        # with '#' will be ignored, and an empty message aborts the commit.
        #
        # On branch master
        # Changes to be committed:
        #
        #
        """
        
        XCTAssertEqual(rule.map(commits: commits), commitsMsgWithHash + "\n\n")
        XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule))
    }
    
    func testRegex() {
        let rule = GitCommitRule.current
        XCTAssertNotNil(rule.regex)
    }
    
    func testDisable() {
        let rule = GitCommitRule(isEnabled: false)
        let commits = "This is a commit message."
        XCTAssertNotNil(rule.regex)
        XCTAssertEqual(rule.regex!.pattern, "^[\\s.]*$")
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
    }
    
    func testIgnoringPattern() {
        let ignoring = "^(MRE-[0-9]+ Automatically bump build number to [0-9]+)$"
        
        let rule = GitCommitRule(ignoringPattern: "\(ignoring)")
        let commits = "MRE-20 Automatically bump build number to 1182"
        XCTAssertFalse(rule.isEnabled(for: commits))
        XCTAssertNotNil(rule.ignoringPattern)
        XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        
        let config =
        """
        enabled: true
        ignoring-pattern: ^(MRE-[0-9]+ Automatically bump build number to [0-9]+)$
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertFalse(rule.scope.isRequired)
            XCTAssertEqual(rule.ignoringPattern, ignoring)
            
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
    }
    
    func testInvalidConfigPath() {
        let path = "invalid"
        do {
            _ = try GitCommitRule(at: path)
        } catch GitCommitError.invalidConfigPath {
            XCTAssertTrue(true)
        } catch _ {
            XCTAssertFalse(true)
        }
    }
    
    func testEmptyConfigs() {
        let path = FileManager.default.currentDirectoryPath + "/emptyConfigs"
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
            _ = try GitCommitRule(at: path)
        } catch GitCommitError.emptyConfigContents(atPath: _) {
            XCTAssertTrue(true)
        } catch _ {
            XCTAssertFalse(false)
        }
    }
    
    func testReadConfigFile() {
        let path = "/Users/devedbox/Library/Mobile Documents/com~apple~CloudDocs/Development/GitCommit/.git-commit.yml"
        guard FileManager.default.fileExists(atPath: path) else {
            return
        }
        
        do {
            let rule = try GitCommitRule(at: path)
            print(rule)
            
            var commits = "This is a commit message."
            XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule))
            
            commits = "chore(GitCommitConfig): This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
            
            commits = "chore(.git-commit.yml): This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch let error {
            print(error)
            XCTAssertFalse(true)
        }
    }
    
    func testRuleConfigurationFile() {
        var config =
        """
        # types: defaults using (feat|fix|docs|style|refactor|test|chore) types.
        #   - feat
        #   - fix
        #   - docs
        #   - style
        #   - refactor
        #   - test
        #   - chore
        # scope:
        #   required: false
        """
        
        do {
            _ = try YAMLDecoder().decode(GitCommitRule.self, from: config)
        } catch _ {
            XCTAssertTrue(true)
        }
        
        config =
        """
        
        """
        
        do {
            _ = try YAMLDecoder().decode(GitCommitRule.self, from: config)
        } catch _ {
            XCTAssertTrue(true)
        }
        
        config =
        """
        """
        
        do {
            _ = try YAMLDecoder().decode(GitCommitRule.self, from: config)
        } catch _ {
            XCTAssertTrue(true)
        }
    }
    
    func testTypes() {
        var config =
        """
        enabled: true
        types:
          -
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertFalse(rule.scope.isRequired)
            XCTAssertTrue(rule.types.count == 1)
            
            let commits = "This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
        
        config =
        """
        enabled: true
        types:
          - feat
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertFalse(rule.scope.isRequired)
            XCTAssertTrue(rule.types.count == 1)
            XCTAssertTrue(rule.types.contains("feat"))
            
            var commits = "feat: This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
            
            commits = "fix: This is a commit message."
            XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
        
        config =
        """
        enabled: true
        types:
          - feat
          - fix
          - ci
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertFalse(rule.scope.isRequired)
            XCTAssertTrue(rule.types.count == 3)
            XCTAssertTrue(rule.types.contains("feat"))
            XCTAssertTrue(rule.types.contains("fix"))
            XCTAssertTrue(rule.types.contains("ci"))
            
            var commits = "feat: This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
            
            commits = "fix: This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
            
            commits = "ci: This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
            
            commits = "docs: This is a commit message."
            XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
    }
    
    func testScopeRequiredCase() {
        var config =
        """
        enabled: true
        scope:
          required: false
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertFalse(rule.scope.isRequired)
            
            let commits = "feat: This is a commit message."
            XCTAssertTrue(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
        
        config =
        """
        enabled: true
        scope:
          required: true
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertTrue(rule.scope.isRequired)
            
            let commits = "feat: This is a commit message."
            XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
    }
    
    func testIgnoresHashAnchoredLines() {
        let config =
        """
        enabled: true
        scope:
          required: false
        """
        
        do {
            let rule = try YAMLDecoder().decode(GitCommitRule.self, from: config)
            XCTAssertFalse(rule.scope.isRequired)
            
            let commits = """
            feat: This is a commit message.

            # Please enter the commit message for your changes. Lines starting
            # with '#' will be ignored, and an empty message aborts the commit.
            #
            # On branch master
            # Changes to be committed:
            #       \tmodified:   GitCommit.xcodeproj/project.xcworkspace/xcuserdata/devedbox.xcuserdatad/UserInterfaceState.xcuserstate
            #       \tmodified:   Sources/GitCommitFramework/Protocols/GitCommitLintable.swift
            #       \tmodified:   Sources/GitCommitFramework/Protocols/GitCommitRuleRepresentable.swift
            #       \tmodified:   Sources/GitCommitFramework/Types/GitCommitRule.swift
            #       \tmodified:   Tests/GitCommitTests/GitCommitRuleTests.swift

            """
            XCTAssertFalse(try GitCommit(stringLiteral: commits).lint(with: rule))
        } catch _ {
            XCTAssertFalse(true)
        }
    }
    
    func testDefaultIsEnabled() {
        let rule = TestIsEnabledGitCommitRule(isEnabled: false)
        XCTAssertFalse(rule.isEnabled)
        XCTAssertEqual(rule.isEnabled, rule.isEnabled(for: "test"))
    }
}
