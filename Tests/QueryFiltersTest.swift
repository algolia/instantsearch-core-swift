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
        
        // Two conjunctive facets with two refinements (one negated).
        filters.addFacetRefinement(name: "foo", value: "bar3")
        filters.addFacetRefinement(name: "abc", value: "tuv", inclusive: false)
        XCTAssertEqual(filters.buildFilters(), "\"abc\":\"xyz\" AND NOT \"abc\":\"tuv\" AND \"foo\":\"bar2\" AND \"foo\":\"bar3\"")
        
        // One conjunctive facet and one disjunctive facet.
        filters.setFacet(withName: "abc", disjunctive: true)
        XCTAssertEqual(filters.buildFilters(), "(\"abc\":\"xyz\" OR NOT \"abc\":\"tuv\") AND \"foo\":\"bar2\" AND \"foo\":\"bar3\"")
        
        // Two disjunctive facets.
        filters.setFacet(withName: "foo", disjunctive: true)
        XCTAssertEqual(filters.buildFilters(), "(\"abc\":\"xyz\" OR NOT \"abc\":\"tuv\") AND (\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        
        // Disjunctive facet with only one refinement.
        filters.removeFacetRefinement(name: "abc", value: "tuv")
        XCTAssertEqual(filters.buildFilters(), "(\"abc\":\"xyz\") AND (\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        
        // Remove all refinements: facet should disappear from filters.
        filters.removeFacetRefinement(name: "abc", value: "xyz")
        XCTAssertEqual(filters.buildFilters(), "(\"foo\":\"bar2\" OR \"foo\":\"bar3\")")
        filters.clearFacetRefinements(name: "foo")
        XCTAssertEqual(filters.buildFilters(), "")
    }
    
    func testFacetExistence() {
        let filters = QueryFilters()
        XCTAssertFalse(filters.hasRefinements())
        XCTAssertFalse(filters.hasFacetRefinements())
        XCTAssertFalse(filters.hasFacetRefinements(name: "foo"))
        
        filters.addFacetRefinement(name: "foo", value: "xxx")
        XCTAssertTrue(filters.hasRefinements())
        XCTAssertTrue(filters.hasFacetRefinements())
        XCTAssertTrue(filters.hasFacetRefinements(name: "foo"))
        XCTAssertFalse(filters.hasFacetRefinements(name: "bar"))
        XCTAssertTrue(filters.hasFacetRefinement(name: "foo", value: "xxx"))
        XCTAssertFalse(filters.hasFacetRefinement(name: "foo", value: "yyy"))
        XCTAssertFalse(filters.hasFacetRefinement(name: "bar", value: "baz"))
        
        filters.toggleFacetRefinement(name: "foo", value: "xxx")
        XCTAssertFalse(filters.hasRefinements())
        XCTAssertFalse(filters.hasFacetRefinements())
        XCTAssertFalse(filters.hasFacetRefinements(name: "foo"))
        XCTAssertFalse(filters.hasFacetRefinement(name: "foo", value: "xxx"))
        
        filters.toggleFacetRefinement(name: "bar", value: "baz")
        XCTAssertTrue(filters.hasRefinements())
        XCTAssertTrue(filters.hasFacetRefinements())
        XCTAssertTrue(filters.hasFacetRefinements(name: "bar"))
        XCTAssertTrue(filters.hasFacetRefinement(name: "bar", value: "baz"))
    }
    
    func testNumericFilters() {
        let filters = QueryFilters()
        
        // Empty filters should produce empty string.
        XCTAssertEqual(filters.buildFilters(), "")
        
        // One conjunctive numeric with one refinement.
        filters.addNumericRefinement("foo", .greaterThanOrEqual, 3)
        XCTAssertEqual(filters.buildFilters(), "\"foo\" >= 3")

        // One conjunctive numeric with two refinements.
        filters.addNumericRefinement("foo", .lessThan, 4.0)
        XCTAssertEqual(filters.buildFilters(), "\"foo\" >= 3 AND \"foo\" < 4")
        
        // Two conjunctive numeric with one refinement.
        filters.removeNumericRefinement(NumericRefinement("foo", .greaterThanOrEqual, 3.0))
        filters.addNumericRefinement(NumericRefinement("bar", .greaterThan, 456.789))
        XCTAssertEqual(filters.buildFilters(), "\"bar\" > 456.789 AND \"foo\" < 4")
        
        // Two conjunctive numerics with two refinements (one negated).
        filters.addNumericRefinement("foo", .notEqual, 0)
        filters.addNumericRefinement("bar", .equal, 0, inclusive: false)
        XCTAssertEqual(filters.buildFilters(), "\"bar\" > 456.789 AND NOT \"bar\" = 0 AND \"foo\" < 4 AND \"foo\" != 0")
        
        // One conjunctive numeric and one disjunctive.
        filters.setNumeric(withName: "foo", disjunctive: true)
        XCTAssertEqual(filters.buildFilters(), "\"bar\" > 456.789 AND NOT \"bar\" = 0 AND (\"foo\" < 4 OR \"foo\" != 0)")
        
        // Two disjunctive numeric.
        filters.setNumeric(withName: "bar", disjunctive: true)
        XCTAssertEqual(filters.buildFilters(), "(\"bar\" > 456.789 OR NOT \"bar\" = 0) AND (\"foo\" < 4 OR \"foo\" != 0)")
        
        // Disjunctive numeric with only one refinement.
        filters.removeNumericRefinement("foo", .lessThan, 4)
        XCTAssertEqual(filters.buildFilters(), "(\"bar\" > 456.789 OR NOT \"bar\" = 0) AND (\"foo\" != 0)")
        
        // Remove all refinements: numerics should disappear from filters.
        filters.removeNumericRefinement("foo", .notEqual, 0.0)
        XCTAssertEqual(filters.buildFilters(), "(\"bar\" > 456.789 OR NOT \"bar\" = 0)")
        filters.clearNumericRefinements(name: "bar")
        XCTAssertEqual(filters.buildFilters(), "")
    }
    
    func testBooleanNumeric() {
        // Boolean numeric filters should use numeric values 0 and 1.
        let filters = QueryFilters()
        filters.addNumericRefinement("boolean", .equal, false)
        XCTAssertEqual(filters.buildFilters(), "\"boolean\" = 0")
        filters.clear()
        filters.addNumericRefinement("boolean", .equal, true)
        XCTAssertEqual(filters.buildFilters(), "\"boolean\" = 1")
    }

    func testNumericExistence() {
        let filters = QueryFilters()
        XCTAssertFalse(filters.hasRefinements())
        XCTAssertFalse(filters.hasNumericRefinements())
        XCTAssertFalse(filters.hasNumericRefinements(name: "foo"))
        
        filters.addNumericRefinement("foo", .greaterThan, -1)
        XCTAssertTrue(filters.hasRefinements())
        XCTAssertTrue(filters.hasNumericRefinements())
        XCTAssertTrue(filters.hasNumericRefinements(name: "foo"))
        XCTAssertFalse(filters.hasNumericRefinements(name: "bar"))
        
        filters.removeNumericRefinement("foo", .greaterThan, -1)
        XCTAssertFalse(filters.hasRefinements())
        XCTAssertFalse(filters.hasNumericRefinements())
        XCTAssertFalse(filters.hasNumericRefinements())
        XCTAssertFalse(filters.hasNumericRefinements(name: "foo"))
    }
    
    func testFacetAndNumeric() {
        let filters = QueryFilters()
        filters.addNumericRefinement("foo", .greaterThanOrEqual, 123)
        filters.addFacetRefinement(name: "abc", value: "something")
        filters.addNumericRefinement("bar", .lessThan, 456.789)
        filters.addFacetRefinement(name: "xyz", value: "other")
        XCTAssertEqual(filters.buildFilters(), "\"abc\":\"something\" AND \"xyz\":\"other\" AND \"bar\" < 456.789 AND \"foo\" >= 123")
    }
}
