import XCTest
@testable import CommitFramework

final class CommitTests: XCTestCase {
    func testLintSimpleFeatureCommits() {
        let verbose = false
        var commits = ""
        
        commits = "feat(SomeScope): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        commits = "fix(SomeBug): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        commits = "docs(Coc): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        commits = "style(CodeStyle): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        commits = "refactor(CodeRefacor): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        commits = "test(UnitTest): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        commits = "chore(AddLibs): This is a commit message."
        XCTAssertTrue(try lint(commits, verbose: verbose))
        
        commits = "fea(SomeScope): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
        commits = "fixs(SomeBug): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
        commits = "doc(Coc): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
        commits = "styling(CodeStyle): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
        commits = "refacte(CodeRefacor): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
        commits = "testing(UnitTest): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
        commits = "choring(AddLibs): This is a commit message."
        XCTAssertFalse(try lint(commits, verbose: verbose))
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
