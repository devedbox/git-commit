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

class GitCommitRuleTests: XCTestCase {
    static var allTests = [
        ("testRegex", testRegex),
        ("testDisable", testDisable),
        ("testInvalidConfigPath", testInvalidConfigPath),
        ("testEmptyConfigs", testEmptyConfigs),
        ("testReadConfigFile", testReadConfigFile),
        ("testRuleConfigurationFile", testRuleConfigurationFile),
        ("testTypes", testTypes),
        ("testScopeRequiredCase", testScopeRequiredCase),
    ]
    
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
}
