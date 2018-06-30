import XCTest
@testable import CommitFramework

final class CommitTests: XCTestCase {
    
    let rule = GitCommitRule()
    
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
        ("testLintSimpleFeatureCommits", testLintSimpleFeatureCommits),
        ("testLintHeaderAndBody", testLintHeaderAndBody),
        ("testLintHeaderAndFooter", testLintHeaderAndFooter),
        ("testLintHeaderAndBodyAndFooter", testLintHeaderAndBodyAndFooter),
    ]
}
