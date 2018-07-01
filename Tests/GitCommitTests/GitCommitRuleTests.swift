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
        ("testRuleConfigurationFile", testRuleConfigurationFile),
        ("testScopeRequiredCase", testScopeRequiredCase),
    ]
    
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
