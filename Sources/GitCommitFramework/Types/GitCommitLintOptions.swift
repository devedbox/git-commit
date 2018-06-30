//
//  GitCommitLintOptions.swift
//  GitCommitFramework
//
//  Created by devedbox on 2018/6/30.
//

// MARK: - GitCommitLintOptions.

public struct GitCommitLintOptions: OptionSet {
    public typealias RawValue = Int
    /// The underlying raw value of the option.
    private let _rawValue: RawValue
    /// Returns the raw value of the option.
    public var rawValue: Int {
        return _rawValue
    }
    
    public init(rawValue: RawValue) {
        _rawValue = rawValue
    }
}

extension GitCommitLintOptions {
    public static let verbose = GitCommitLintOptions(rawValue: 1 << 0)
}
