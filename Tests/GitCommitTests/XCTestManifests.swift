import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(GitCommitTests.allTests),
        testCase(GitCommitRuleTests.allTests),
    ]
}
#endif
