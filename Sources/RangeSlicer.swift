//
//  Copyright (c) 2016 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation


/// Split arbitrary numeric ranges into slices according to a pattern.
///
/// The slicer uses a logarithmic scale, so that it can handle ranges with several orders of magnitude in amplitude.
/// The pattern must start at 1. The base of the logarithm is the highest number in the pattern.
/// Intermediate numbers (if any) provide intermediate steps. The pattern is repeated at each order of magnitude,
/// until the input range is covered.
///
/// The slices produced are assumed to be lower bound inclusive, higher bound exclusive (which fits prices well).
///
/// It is typically meant to be used with numeric facets (e.g. using the minimum and maximum values returned in the
/// search response's facet stats), although other use cases are of course possible.
///
/// ### Examples
///
/// - If the pattern is [1, 2, 5, 10] and the input range is [0.31, 199.99], the slicer will produce the
///   following steps: [0.20, 0.50, 1, 2, 5, 10, 20, 50, 100, 200]. (The actual result is a list of adjacent ranges.)
///
/// - If the pattern is [1, 2], it will produce a binary scale: for example, the input range [0.33, 9.99] will produce
///   steps [0.25, 0.5, 1, 2, 4, 8, 16].
///
public class RangeSlicer {
    // MARK: - Properties
    
    /// Pattern used to slice ranges.
    var pattern: [Double] {
        // Check pattern consistency before setting.
        willSet(newValue) {
            RangeSlicer.checkPattern(newValue)
        }
    }
    
    /// Check that a pattern is valid.
    /// This method will assert if it's not.
    ///
    /// - parameter pattern: Pattern to check.
    ///
    private static func checkPattern(_ pattern: [Double]) {
        assert(pattern.count >= 2, "Pattern must contain at least two steps")
        assert(pattern[0] == 1, "Pattern must start at 1")
        var lastValue = pattern[0]
        for i in 1..<pattern.count {
            assert(pattern[i] > lastValue, "Pattern steps must be in increasing order")
            lastValue = pattern[i]
        }
    }
    
    /// Logarithmic base: last element in the pattern.
    public var base: Double { return pattern.last! }
    
    // MARK: - Constants
    
    /// Default pattern.
    public static let defaultPattern: [Double] = [1, 2, 5, 10]
    
    // MARK: - Initialization
    
    /// Create a slicer with the default pattern.
    ///
    public init() {
        self.pattern = RangeSlicer.defaultPattern
    }
    
    /// Create a slicer with a given pattern.
    ///
    /// - parameter pattern: The pattern to use.
    ///
    public init(pattern: [Double]) {
        RangeSlicer.checkPattern(pattern)
        self.pattern = pattern
    }
    
    // MARK: - Operations
    
    /// Slice a range according to this slicer's pattern.
    ///
    /// - parameter range: Range to be sliced.
    /// - returns: The computed slices. They are guaranteed to be contiguous and cover the entire input range.
    ///
    public func slice(range: ClosedRange<Double>) -> [Range<Double>] {
        var ranges = [Range<Double>]()
        let minExponent = Int(floor(_log(range.lowerBound)))
        let maxExponent = Int(ceil(_log(range.upperBound)))
        for exponent in minExponent...maxExponent {
            let multiplier = pow(base, Double(exponent))
            let steps = pattern.map({ return $0 * multiplier })
            for i in 0 ..< pattern.count - 1 {
                let low = steps[i]
                let high = steps[i + 1]
                let currentRange = low ..< high
                if currentRange.overlaps(range) {
                    ranges.append(currentRange)
                }
            }
        }
        return ranges
    }
    
    /// Compute a logarithm in the base of this slicer.
    ///
    /// - parameter value: Argument to the logarithm.
    /// - returns: Logarithm in base `base` of `value`.
    ///
    private func _log(_ value: Double) -> Double {
        return log(value) / log(base)
    }
}
