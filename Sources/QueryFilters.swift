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


/// A refinement of a facet.
@objc public class FacetRefinement: NSObject {
    // MARK: Properties
    
    /// Name of the facet.
    @objc public var name: String
    
    /// Value for the facet.
    @objc public var value: String
    
    /// Whether the refinement is inclusive (default) or exclusive (value prefixed with a dash).
    @objc public var inclusive: Bool = true
    
    // MARK: Initialization

    @objc public init(name: String, value: String, inclusive: Bool = true) {
        self.name = name
        self.value = value
        self.inclusive = inclusive
    }

    @objc public init(copy: FacetRefinement) {
        self.name = copy.name
        self.value = copy.value
        self.inclusive = copy.inclusive
    }
    
    // MARK: Debug
    
    override public var description: String {
        return "FacetRefinement{\(buildFilter())}"
    }
    
    // MARK: Equatable
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? FacetRefinement else {
            return false
        }
        return self.name == rhs.name
            && self.value == rhs.value
            && self.inclusive == rhs.inclusive
    }

    // MARK: Methods

    /// Build a facet filter corresponding to this refinement.
    ///
    /// + Deprecated: Please use `buildFilter()` instead.
    ///
    /// - returns: A string suitable for use in `Query.facetFilters`.
    ///
    @objc public func buildFacetFilter() -> String {
        return "\(name):\(buildFacetRefinement())"
    }
    
    /// Build a facet refinement corresponding to this value.
    ///
    /// - returns: A string suitable for use in `Index.searchDisjunctiveFaceting(...)`.
    ///
    @objc public func buildFacetRefinement() -> String {
        return inclusive ? value : "-" + value
    }
    
    /// Build a filter corresponding to this refinement.
    ///
    /// - returns: An expression suitable for use in `Query.filters`.
    ///
    @objc public func buildFilter() -> String {
        let escapedName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let escapedValue = value.replacingOccurrences(of: "\"", with: "\\\"")
        let filter = "\"\(escapedName)\":\"\(escapedValue)\""
        return inclusive ? filter : "NOT " + filter
    }
}


/// A high-level representation of a query's filter.
///
/// This class allows manipulating facet and numeric filters individually, then combining them into a string
/// suitable for use in `Query.filters`.
///
/// + Note: Tags are not handled. Please use facets instead, as they are more powerful.
///
@objc public class QueryFilters: NSObject {
    // MARK: - Properties
    
    /// Facets that will be treated as disjunctive.
    @objc public private(set) var disjunctiveFacets: Set<String>

    /// Facet refinements. Maps facet names to a list of refined values.
    /// The format is the same as `Index.searchDisjunctiveFaceting()`.
    ///
    @objc public private(set) var facetRefinements: [String: [FacetRefinement]]
    
    /// Numeric attributes that will be treated as disjunctive.
    @objc public private(set) var disjunctiveNumerics: Set<String>

    // MARK: - Initialization
    
    /// Create new, empty query filters.
    ///
    @objc public override init() {
        self.disjunctiveFacets = Set<String>()
        self.disjunctiveNumerics = Set<String>()
        self.facetRefinements = [:]
    }

    /// Create a copy of given query filters.
    ///
    /// - parameter copy: The filters to copy from.
    ///
    @objc public init(copy: QueryFilters) {
        self.disjunctiveFacets = copy.disjunctiveFacets
        self.disjunctiveNumerics = copy.disjunctiveNumerics
        // Deep copy the facet refinements.
        // TODO: Maybe there is an easier way to do it?
        var newFacetRefinements = [String: [FacetRefinement]]()
        for (facetName, refinements) in copy.facetRefinements {
            var newRefinements = [FacetRefinement]()
            for refinement in refinements {
                newRefinements.append(FacetRefinement(copy: refinement))
            }
            newFacetRefinements[facetName] = newRefinements
        }
        self.facetRefinements = newFacetRefinements
    }
    
    /// Reset to an empty state.
    ///
    @objc public func clear() {
        clearFacetRefinements()
    }
    
    // MARK: - Equatable
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let rhs = object as? QueryFilters else {
            return false
        }
        if self.disjunctiveFacets != rhs.disjunctiveFacets || self.disjunctiveNumerics != rhs.disjunctiveNumerics {
            return false
        }
        let lhsFacets = Array(self.facetRefinements.keys)
        let rhsFacets = Array(rhs.facetRefinements.keys)
        if lhsFacets != rhsFacets {
            return false
        }
        for facetName in lhsFacets {
            if self.facetRefinements[facetName]! != rhs.facetRefinements[facetName]! {
                return false
            }
        }
        return true
    }

    // MARK: - Generate filters
    
    /// Generate a filter expression from the current filters.
    ///
    /// - returns: An expression suitable for use with `Query.filters`.
    ///
    @objc public func buildFilters() -> String {
        // NOTE: Sort facet names to get predictable output.
        let facetFilters = facetRefinements.keys.sorted().flatMap({ (facetName: String) -> String? in
            let refinements = self.facetRefinements[facetName]!
            if refinements.isEmpty {
                return nil
            }
            if self.isDisjunctiveFacet(name: facetName) {
                let innerFilters = refinements.map({ return $0.buildFilter() }).joined(separator: " OR ")
                return "(\(innerFilters))"
            } else {
                return refinements.map({ return $0.buildFilter() }).joined(separator: " AND ")
            }
        }).joined(separator: " AND ")
        return [facetFilters].joined(separator: " AND ")
    }
    
    /// Generate facet refinements from the current filters.
    ///
    /// - returns: Facet refinements suitable for use with `Index.searchDisjunctiveFaceting(...)`.
    ///
    @objc public func buildFacetRefinements() -> [String: [String]] {
        var stringRefinements = [String: [String]]()
        for (facetName, refinements) in facetRefinements {
            stringRefinements[facetName] = refinements.map({ $0.buildFacetRefinement() })
        }
        return stringRefinements
    }
    
    /// Generate facet filters from the current filters.
    ///
    /// - returns: An expression suitable for use with `Query.facetFilters`.
    ///
    @objc public func buildFacetFilters() -> [Any] {
        var facetFilters = [Any]()
        for (facetName, refinements) in facetRefinements {
            if isDisjunctiveFacet(name: facetName) {
                var innerFacetFilters = [Any]()
                for refinement in refinements {
                    innerFacetFilters.append(refinement.buildFacetFilter())
                }
                facetFilters.append(innerFacetFilters)
            } else {
                for refinement in refinements {
                    facetFilters.append(refinement.buildFacetFilter())
                }
            }
        }
        return facetFilters
    }

    // MARK: - Facets
    
    /// Set a given facet as disjunctive or conjunctive.
    ///
    /// - parameter name: The facet's name.
    /// - parameter disjunctive: true to treat this facet as disjunctive (`OR`), false to treat it as conjunctive
    ///   (`AND`, the default).
    ///
    @objc public func setFacet(withName name: String, disjunctive: Bool) {
        if disjunctive {
            disjunctiveFacets.insert(name)
        } else {
            disjunctiveFacets.remove(name)
        }
    }
    
    /// Test whether a given facet is disjunctive or conjunctive.
    ///
    /// - parameter name: The facet's name.
    /// - returns: true if this facet is disjunctive (`OR`), false if it's conjunctive (`AND`).
    ///
    @objc public func isDisjunctiveFacet(name: String) -> Bool {
        return disjunctiveFacets.contains(name)
    }
    
    /// Add a refinement for a given facet.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the facet's own
    /// disjunctive/conjunctive status.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to add.
    ///
    @objc public func addFacetRefinement(name: String, value: String, inclusive: Bool = true) {
        if facetRefinements[name] == nil {
            facetRefinements[name] = []
        }
        facetRefinements[name]!.append(FacetRefinement(name: name, value: value, inclusive: inclusive))
    }
    
    /// Remove a refinement for a given facet.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to remove.
    ///
    @objc public func removeFacetRefinement(name: String, value: String) {
        if let index = facetRefinements[name]?.index(where: { $0.name == name && $0.value == value }) {
            facetRefinements[name]!.remove(at: index)
            if facetRefinements[name]!.isEmpty {
                facetRefinements.removeValue(forKey: name)
            }
        }
    }
    
    /// Test whether a facet has a refinement for a given value.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to look for.
    /// - returns: true if the refinement exists, false otherwise.
    ///
    @objc public func hasFacetRefinement(name: String, value: String) -> Bool {
        return facetRefinements[name]?.contains(where: { $0.name == name && $0.value == value }) ?? false
    }
    
    /// Test whether a facet has any refinement(s).
    ///
    /// - parameter name: The facet's name.
    /// - returns: true if the facet has at least one refinment, false if it has none.
    ///
    @objc public func hasFacetRefinement(name: String) -> Bool {
        if let facetRefinements = facetRefinements[name] {
            return !facetRefinements.isEmpty
        } else {
            return false
        }
    }
    
    /// Add or remove a facet refinement, based on its current state: if it exists, it is removed; otherwise it is
    /// added.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to toggle.
    ///
    @objc public func toggleFacetRefinement(name: String, value: String) {
        if hasFacetRefinement(name: name, value: value) {
            removeFacetRefinement(name: name, value: value)
        } else {
            addFacetRefinement(name: name, value: value)
        }
    }
    
    /// Remove all refinements for all facets.
    ///
    @objc public func clearFacetRefinements() {
        facetRefinements.removeAll()
    }
    
    /// Remove all refinements for a given facet.
    ///
    /// - parameter name: The facet's name.
    ///
    @objc public func clearFacetRefinements(name: String) {
        facetRefinements.removeValue(forKey: name)
    }
}
