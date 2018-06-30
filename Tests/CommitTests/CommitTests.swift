import XCTest
@testable import CommitFramework

final class CommitTests: XCTestCase {
    func testLintSimpleFeatureCommits() {
        let verbose = false
        var commits = ""
        
        let asciiCommits = "This is a commit message."
        let unicodeCommits = "这是一条提交信息。"
        
        let asciiScope = "SomeScope"
        let unicudeScope = "提交域"
        
        func runTest(for scope: String, with targetCommits: String) {
            commits = "feat(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            commits = "fix(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            commits = "docs(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            commits = "style(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            commits = "refactor(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            commits = "test(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            commits = "chore(\(scope)): \(targetCommits)"
            XCTAssertTrue(try lint(commits, verbose: verbose))
            
            commits = "fea(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
            commits = "fixs(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
            commits = "doc(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
            commits = "styling(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
            commits = "refacte(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
            commits = "testing(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
            commits = "choring(\(scope)): \(targetCommits)"
            XCTAssertFalse(try lint(commits, verbose: verbose))
        }
        
        runTest(for: asciiScope, with: asciiCommits)
        runTest(for: unicudeScope, with: asciiCommits)
        runTest(for: asciiScope, with: unicodeCommits)
        runTest(for: unicudeScope, with: unicodeCommits)
        runTest(for: asciiScope + unicudeScope,
                with: asciiCommits + unicodeCommits)
    }
    
    func testLintHeaderAndBody() {
        let verbose = true
        var commits = ""
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        """
        
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        
        The first line of specific message.
        The second line of specific message.
        """
        
        XCTAssertFalse(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        
        The second line of specific message.
        """
        
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        """
        XCTAssertFalse(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        
        
        
        """
        XCTAssertFalse(try lint(commits, verbose: verbose))
    }
    
    func testLintHeaderAndFooter() {
        let verbose = true
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
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
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
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
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
        XCTAssertFalse(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertFalse(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        Closes #8989, #3131, #issue3, &issue4
        
        """
        XCTAssertFalse(try lint(commits, verbose: verbose))
    }
    
    func testLintHeaderAndBodyAndFooter() {
        let verbose = true
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
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
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
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
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
        XCTAssertFalse(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        
        Closes #8989, #3131, #issue3, &issue4
        """
        XCTAssertFalse(try lint(commits, verbose: verbose))
        
        commits = """
        feat(SomeFeature): This is a message.
        
        The first line of specific message.
        The second line of specific message.
        
        Closes #8989, #3131, #issue3, &issue4
        
        """
        XCTAssertFalse(try lint(commits, verbose: verbose))
    }

    static var allTests = [
        ("testLintSimpleFeatureCommits", testLintSimpleFeatureCommits),
        ("testLintHeaderAndBody", testLintHeaderAndBody),
        ("testLintHeaderAndFooter", testLintHeaderAndFooter),
        ("testLintHeaderAndBodyAndFooter", testLintHeaderAndBodyAndFooter),
    ]
}
