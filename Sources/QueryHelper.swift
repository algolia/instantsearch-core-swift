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

import AlgoliaSearch
import Foundation


/// A refinement of a facet.
@objc internal class FacetRefinement: NSObject {
    /// Name of the facet.
    @objc var name: String
    
    /// Value for the facet.
    @objc var value: String

    /// Whether the refinement is inclusive (default) or exclusive (value prefixed with a dash).
    @objc var inclusive: Bool = true
    
    /// Build a facet filter corresponding to this refinement.
    @objc func buildFacetFilter() -> String {
        return "\(name):\(inclusive ? "" : "-")\(value)"
    }
    
    @objc init(name: String, value: String, inclusive: Bool = true) {
        self.name = name
        self.value = value
        self.inclusive = inclusive
    }
}

internal func ==(lhs: FacetRefinement, rhs: FacetRefinement) -> Bool {
    return lhs.name == rhs.name && lhs.value == rhs.value && lhs.inclusive == rhs.inclusive
}


/// Utilities to build and interpret `Query` instances.
///
@objc internal class QueryHelper: NSObject {
    /// The query wrapped by this helper.
    @objc let query: Query
    
    /// Create a query helper initially wrapping the empty query.
    @objc convenience override init() {
        self.init(query: Query())
    }
    
    /// Create a query builder wrapping the specified query.
    @objc init(query: Query) {
        self.query = query
    }
    
    // MARK: - Facets
    
    /// Test whether the query contains the specified facet refinement.
    /// The test looks for both conjunctive or disjunctive refinements.
    ///
    @objc func hasFacetRefinement(_ facetRefinement: FacetRefinement) -> Bool {
        return findFacetRefinement({ $0 == facetRefinement }) != nil
    }
    
    /// Add a conjunctive facet refinement (`AND`).
    /// As per the query syntax, it will be added at the first level of the facet filters.
    ///
    /// - parameter facetRefinement: The facet refinement to add.
    ///
    @objc func addConjunctiveFacetRefinement(_ facetRefinement: FacetRefinement) {
        query.facetFilters = query.facetFilters ?? []
        query.facetFilters?.append(facetRefinement.buildFacetFilter())
    }

    @objc func toggleConjunctiveFacetRefinement(_ facetRefinement: FacetRefinement) {
        if hasFacetRefinement(facetRefinement) {
            removeFacetRefinement(facetRefinement)
        } else {
            addConjunctiveFacetRefinement(facetRefinement)
        }
    }

    /// Add a disjunctive facet refinement (`OR`).
    /// As per the query syntax, it will be added at the second level of the facet filters (i.e. inside a nested array).
    ///
    /// **Note:** If refinements already exist for the same facet, this new refinements will be added to the first
    /// occurrence (and that occurrence will be converted to a nested array if necessary).
    ///
    /// - parameter facetRefinement: The facet refinement to add.
    ///
    @objc func addDisjunctiveFacetRefinement(_ facetRefinement: FacetRefinement) {
        let newValue = facetRefinement.buildFacetFilter()
        // If the facet already has refined values, add them to this list.
        if let indices = findFacetRefinement({ $0.name == facetRefinement.name }) {
            let filters = query.facetFilters![indices[0]]
            // If it's already an array, add to it.
            if var array = filters as? [Any] {
                array.append(newValue)
                query.facetFilters![indices[0]] = array
            }
            // Otherwise create an array with the current value plus the new one.
            else if let string = filters as? String {
                query.facetFilters![indices[0]] = [string, newValue]
            } else {
                assert(false) // should never happen
            }
        }
        // Otherwise, add a new array.
        else {
            query.facetFilters = query.facetFilters ?? []
            query.facetFilters?.append([newValue])
        }
    }

    /// Toggle a disjunctive facet refinement.
    /// This method adds the refinement if it does not already exists, and removes it otherwise.
    ///
    /// - parameter facetRefinement: The facet refinement to toggle.
    ///
    @objc func toggleDisjunctiveFacetRefinement(_ facetRefinement: FacetRefinement) {
        if hasFacetRefinement(facetRefinement) {
            removeFacetRefinement(facetRefinement)
        } else {
            addDisjunctiveFacetRefinement(facetRefinement)
        }
    }

    /// Remove a facet refinement.
    /// Works for both conjunctive and disjunctive refinements.
    ///
    /// **Note:** In case the refinement appears more than once, this will only remove its first occurrence.
    ///
    /// - parameter facetRefinement: The facet refinement to remove.
    ///
    @objc func removeFacetRefinement(_ facetRefinement: FacetRefinement) {
        if let indices = findFacetRefinement({ $0 == facetRefinement }) {
            assert(indices.count == 1 || indices.count == 2)
            if indices.count == 1 {
                query.facetFilters?.remove(at: indices[0])
            } else if indices.count == 2 {
                var newArray = query.facetFilters?[indices[0]] as! [Any]
                newArray.remove(at: indices[1])
                if newArray.isEmpty {
                    query.facetFilters?.remove(at: indices[0])
                } else {
                    query.facetFilters?[indices[0]] = newArray
                }
            }
        }
    }

    /// Retrieve all facet refinements matching a predicate.
    ///
    /// - parameter matching: A predicate indicating which refinements should match.
    /// - returns: The list of matching refinements.
    ///
    @objc func getFacetRefinements(_ matching: (FacetRefinement) -> Bool) -> [FacetRefinement] {
        if let facetFilters = query.facetFilters {
            return _getFacetRefinements(facetFilters, matching: matching)
        } else {
            return []
        }
    }
    
    private func _getFacetRefinements(_ facetFilters: [Any], matching: (FacetRefinement) -> Bool) -> [FacetRefinement] {
        var results = [FacetRefinement]()
        for value in facetFilters {
            if let stringFilter = value as? String, let refinement = QueryHelper.parseFacetRefinement(stringFilter) {
                if matching(refinement) {
                    results.append(refinement)
                }
            } else if let facetFilters = value as? [Any] {
                let subresults = _getFacetRefinements(facetFilters, matching: matching)
                results.append(contentsOf: subresults)
            }
        }
        return results
    }

    /// Find the location of the first refinement matching a predicate.
    private func findFacetRefinement(_ matching: (FacetRefinement) -> Bool) -> [Int]? {
        if let facetFilters = query.facetFilters {
            return _findFacetRefinement(facetFilters, matching: matching)
        } else {
            return nil
        }
    }

    /// Auxiliary recursive function to find a facet refinement.
    private func _findFacetRefinement(_ facetFilters: [Any], matching: (FacetRefinement) -> Bool) -> [Int]? {
        for (index, value) in facetFilters.enumerated() {
            if let stringFilter = value as? String, let refinement = QueryHelper.parseFacetRefinement(stringFilter) {
                if matching(refinement) {
                    return [index]
                }
            } else if let facetFilters = value as? [Any] {
                if let subindices = _findFacetRefinement(facetFilters, matching: matching) {
                    return [index] + subindices
                }
            }
        }
        return nil
    }

    /// Parse a facet filter into a facet refinement.
    ///
    /// - parameter facetFilter: A string representation of a facet filter, as used by `Query`.
    /// - returns: The corresponding facet refinement, or nil if the string is invalid.
    ///
    private static func parseFacetRefinement(_ facetFilter: String) -> FacetRefinement? {
        let components = facetFilter.characters.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        if components.count == 2 {
            let facetName = String(components[0])
            var facetValue = String(components[1])
            var inclusive = true
            if facetValue.characters.first == "-" {
                facetValue = facetValue.substring(from: facetValue.characters.index(after: facetValue.startIndex))
                inclusive = false
            }
            return FacetRefinement(name: facetName, value: facetValue, inclusive: inclusive)
        } else {
            return nil
        }
    }
}
