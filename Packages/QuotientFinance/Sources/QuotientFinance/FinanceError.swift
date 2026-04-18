// FinanceError.swift

import Foundation

/// Errors produced by the calculation engine when iterative solvers
/// fail to converge or inputs are outside their domain.
public enum FinanceError: Error, Sendable, Hashable, CustomStringConvertible {
    case solverDidNotConverge(function: String, iterations: Int)
    case invalidInput(String)

    public var description: String {
        switch self {
        case let .solverDidNotConverge(fn, iters):
            return "\(fn) did not converge within \(iters) iterations"
        case let .invalidInput(msg):
            return "Invalid input: \(msg)"
        }
    }
}
