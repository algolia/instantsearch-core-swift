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

@testable import AlgoliaSearchHelper
import XCTest


class RangeSlicerTests: XCTestCase {
    
    /// Test with default pattern.
    func testDefault() {
        let slicer = RangeSlicer()
        
        // Zero-width range should produce only one slice.
        XCTAssertEqual(slicer.slice(range: 1.0 ... 1.0), [1.0 ..< 2.0])
        
        // Widen the range progressively.
        XCTAssertEqual(slicer.slice(range: 1.00 ... 1.99), [1.0 ..< 2.0])
        XCTAssertEqual(slicer.slice(range: 1.30 ... 3.78), [1.0 ..< 2.0, 2.0 ..< 5.0])
        XCTAssertEqual(slicer.slice(range: 1.15 ... 6.67), [1.0 ..< 2.0, 2.0 ..< 5.0, 5.0 ..< 10.0])
        XCTAssertEqual(slicer.slice(range: 2.88 ... 13.22), [2.0 ..< 5.0, 5.0 ..< 10.0, 10.0 ..< 20.0])
        XCTAssertEqual(slicer.slice(range: 5.00 ... 49.99), [5.0 ..< 10.0, 10.0 ..< 20.0, 20.0 ..< 50.0])
        XCTAssertEqual(slicer.slice(range: 9.99 ... 88.88), [5.0 ..< 10.0, 10.0 ..< 20.0, 20.0 ..< 50.0, 50.0 ..< 100.0])
        XCTAssertEqual(slicer.slice(range: 0.75 ... 175.25), [0.50 ..< 1.0, 1.0 ..< 2.0, 2.0 ..< 5.0, 5.0 ..< 10.0, 10.0 ..< 20.0, 20.0 ..< 50.0, 50.0 ..< 100.0, 100.0 ..< 200.0])
        XCTAssertEqual(slicer.slice(range: 0.30 ... 300.00), [0.20 ..< 0.50, 0.50 ..< 1.0, 1.0 ..< 2.0, 2.0 ..< 5.0, 5.0 ..< 10.0, 10.0 ..< 20.0, 20.0 ..< 50.0, 50.0 ..< 100.0, 100.0 ..< 200.0, 200.0 ..< 500.0])
        XCTAssertEqual(slicer.slice(range: 0.10 ... 999.99), [0.10 ..< 0.20, 0.20 ..< 0.50, 0.50 ..< 1.0, 1.0 ..< 2.0, 2.0 ..< 5.0, 5.0 ..< 10.0, 10.0 ..< 20.0, 20.0 ..< 50.0, 50.0 ..< 100.0, 100.0 ..< 200.0, 200.0 ..< 500.0, 500.0 ..< 1000.0])
    }
    
    func testCustom() {
        let slicer1 = RangeSlicer(pattern: [1, 2])
        XCTAssertEqual(slicer1.slice(range: 0.33 ... 55.5), [0.25 ..< 0.5, 0.5 ..< 1.0, 1.0 ..< 2.0, 2.0 ..< 4.0, 4.0 ..< 8.0, 8.0 ..< 16.0, 16.0 ..< 32.0, 32.0 ..< 64.0])
        
        let slicer2 = RangeSlicer(pattern: [1, 3, 10])
        XCTAssertEqual(slicer2.slice(range: 45.67 ... 299.99), [30.0 ..< 100.0, 100.0 ..< 300.0])
    }
}
