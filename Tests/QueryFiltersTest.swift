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
import Foundation
import XCTest


class QueryFiltersTest: XCTestCase {
    
    func testFacetFilters() {
        let filters = QueryFilters()
        
        // Empty filters should produce empty string.
        XCTAssertEqual(filters.buildFilters(), "")
        
        // One conjunctive facet with one refinement.
        filters.addFacetRefinement(name: "foo", value: "bar1")
        XCTAssertEqual(filters.buildFilters(), "\"foo\":\"bar1\"")
        
        // One conjunctive facet with two refinements.
        filters.addFacetRefinement(name: "foo", value: "bar2")
        XCTAssertEqual(filters.buildFilters(), "\"foo\":\"bar1\" AND \"foo\":\"bar2\"")
        
        // Two conjunctive facets with one refinement.
        filters.removeFacetRefinement(name: "foo", value: "bar1")
        filters.addFacetRefinement(name: "abc", value: "xyz")
        XCTAssertEqual(filters.buildFilters(), "\"abc\":\"xyz\" AND \"foo\":\"bar2\"")
        
        // Two conjunctive facets with two refinements.
        filters.addFacetRefinement(name: "foo", value: "bar3")
        filters.addFacetRefinement(name: "abc", value: "tuv")
        XCTAssertEqual(filters.buildFilters(), "\"abc\":\"xyz\" AND \"abc\":\"tuv\" AND \"foo\":\"bar2\" AND \"foo\":\"bar3\"")
        
        // One conjunctive facet and one disjunctive facet.
        filters.setFacet(withName: "abc", disjunctive: true)
        XCTAssertEqual(filters.buildFilters(), "(\"abc\":\"xyz\" OR \"abc\":\"tuv\") AND \"foo\":\"bar2\" AND \"foo\":\"bar3\"")
        
        // Two disjunctive facets.
        filters.setFacet(withName: "foo", disjunctive: true)
        XCTAssertEqual(filters.buildFilters(), "(\"abc\":\"xyz\" OR \"abc\":\"tuv\") AND (\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        
        // Disjunctive facet with only one refinement.
        filters.removeFacetRefinement(name: "abc", value: "tuv")
        XCTAssertEqual(filters.buildFilters(), "(\"abc\":\"xyz\") AND (\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        
        // Remove all refinements: facet should disappear from filters.
        filters.removeFacetRefinement(name: "abc", value: "xyz")
        XCTAssertEqual(filters.buildFilters(), "(\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        filters.clearFacetRefinements(name: "foo")
        XCTAssertEqual(filters.buildFilters(), "")
    }
    
    func testCopy() {
        let filters1 = QueryFilters()
        filters1.addFacetRefinement(name: "foo", value: "bar")
        let filters2 = QueryFilters(copy: filters1)
        XCTAssertEqual(filters1, filters2)
        filters2.addFacetRefinement(name: "foo", value: "baz")
        XCTAssertNotEqual(filters1, filters2)
    }
    
    func testEquality() {
        let filters1 = QueryFilters()
        filters1.addFacetRefinement(name: "foo", value: "bar")
        let filters2 = QueryFilters()
        filters2.addFacetRefinement(name: "foo", value: "bar")
        XCTAssertEqual(filters1, filters2)
    }
}
