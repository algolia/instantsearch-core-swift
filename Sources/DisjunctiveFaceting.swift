//
//  DisjunctiveFacetingHelper.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 26/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// Provides convenient method for building disjuncitve faceting queries and parsing disjunctive faceting

public class DisjunctiveFacetingHelper {
  
  /// Blocks instantiating this class
  
  private init() {}
  
  /// Convenient method for building query list for disjunctive faceting with delegate instance
  /// - parameter query: base search query
  /// - parameter delegate: disjunctive faceting delegate
  /// - returns: list of queries for disjunctive faceting
  
  public static func buildQueries(with query: Query, delegate: DisjunctiveFacetingDelegate) -> [Query] {
    let facets = delegate.disjunctiveFacetsAttributes
    let filters = delegate.filterList
    return buildQueries(with: query, disjunctiveFacets: facets, filters: filters)
  }
  
  /// Build list of queries for disjuncitve faceting
  /// - parameter query: base search query
  /// - parameter disjunctiveFacets: set of disjunctive filters attributes
  /// - parameters filters: list of search filters
  /// - returns: list of queries for disjunctive faceting
  
  public static func buildQueries(with query: Query, disjunctiveFacets: Set<Attribute>, filters: [FilterType]) -> [Query] {
    let (filtersOr, filtersAnd) = filters.partition { disjunctiveFacets.contains($0.attribute) }
    let andQuery = buildAndQuery(query: query, filtersAnd: filtersAnd, filtersOr: filtersOr)
    let orQueries = buildOrQueries(query: query, filtersAnd: filtersAnd, filtersOr: filtersOr, disjunctiveFacets: disjunctiveFacets)
    return [andQuery] + orQueries
  }
  
  /// Merges multi-query results of disjuncitve faceting request to one result containing disjunctive faceting information
  /// - parameter results: search results of disjunctive faceting multi-query
  /// - returns: unique search result containing information of disjunctive faceting multi-query response
  
  public static func mergeResults(_ results: [SearchResults]) -> SearchResults {
    
    let resultAnd = results.first!
    let resultsOr = results[1..<results.endIndex]
    
    let facets: [Attribute: [Facet]] = resultsOr
      .compactMap { $0.facets }
      .reduce([:]) { $0.merging($1) { (v, _) in v } }
    let facetStats = results
      .compactMap { $0.facetStats }
      .reduce([:]) { $0.merging($1) { (v, _) in v } }
    
    var output = resultAnd
    
    output.disjunctiveFacets = facets
    output.facetStats = facetStats
    output.areFacetsCountExhaustive = resultsOr.compactMap { $0.areFacetsCountExhaustive }.all { $0 }
    
    return output
  }
  
  /// Constructs dictionary of raw facets for attribute with filters and set of disjunctive faceting attributes
  /// - parameter disjunctiveFacets: set of disjuncitve faceting attributes
  /// - parameter filters: list of filters containing disjunctive facets
  /// - returns: dictionary mapping disjunctive faceting attributes to list of raw facets
  
  private static func facetDictionary(with disjunctiveFacets: Set<Attribute>, filters: [FilterType]) -> [Attribute: [String]] {
    return disjunctiveFacets.map { attribute -> (Attribute, [String]) in
      let values = filters
        .compactMap { $0 as? Filter.Facet }
        .filter { $0.attribute == attribute  }
        .map { $0.value.description }
      return (attribute, values)
    }.reduce([:]) { dict, val in
      return dict.merging([val.0: val.1]) { v, _ in v }
    }
  }
  
  /// Constructs dictionary of facets for attribute with filters and set of disjunctive faceting attributes
  /// Each generated facet is zero-count
  /// - parameter disjunctiveFacets: set of disjuncitve faceting attributes
  /// - parameter filters: list of filters containing disjunctive facets
  /// - returns: dictionary mapping disjunctive faceting attributes to list of facets
  
  private static func typedFacetDictionary(with dict: [Attribute: [String]]) -> [Attribute: [Facet]] {
    return dict
      .map { (attribute, facetValues) -> (Attribute, [Facet]) in
        let facets = facetValues.map { Facet(value: $0, count: 0, highlighted: .none) }
        return (attribute, facets)
      }
      .reduce([:]) { dict, arg in
        return dict.merging([arg.0: arg.1]) { v, _ in v }
      }
  }
  
  /// Completes disjunctive faceting result with currently selected facets with empty results
  /// - parameter results: base disjuncitve faceting results
  /// - parameter facets: dictionary of current facets
  /// - returns: disjuncitve faceting results enriched with selected but empty facets
  
  public static func completeMissingFacets(in results: SearchResults, with facets: [Attribute: [String]]) -> SearchResults {
    
    var output = results
    
    func complete(lhs: [Facet], withFacetValues facetValues: Set<String>) -> [Facet] {
      let existingValues = lhs.map { $0.value }
      return lhs + facetValues.subtracting(existingValues).map { Facet(value: $0, count: 0, highlighted: .none) }
    }

    guard let currentDisjunctiveFacets = results.disjunctiveFacets else {
      output.disjunctiveFacets = typedFacetDictionary(with: facets)
      return output
    }
    
    facets.forEach { attribute, values in
      let facets = currentDisjunctiveFacets[attribute] ?? []
      let completedFacets = complete(lhs: facets, withFacetValues: Set(values))
      output.disjunctiveFacets?[attribute] = completedFacets
    }

    return output
    
  }
  
  /// Completes disjunctive faceting result with currently selected facets with empty results
  /// - parameter results: base disjuncitve faceting results
  /// - parameter facets: set of attribute of facets
  /// - returns: disjuncitve faceting results enriched with selected but empty facets
  
  public static func completeMissingFacets(in results: SearchResults, disjunctiveFacets: Set<Attribute>, filters: [FilterType]) -> SearchResults {
    let facetDictionary = self.facetDictionary(with: disjunctiveFacets, filters: filters)
    return completeMissingFacets(in: results, with: facetDictionary)
  }
  
  /// Builds "and" query necessary for base disjuncitve faceting result
  /// - parameter query: source query
  /// - parameter filtersAnd: filters in conjunctive groups
  /// - parameter filtersOr: filters in disjunctive groups
  /// - returns: "and" query for disjunctive faceting
  
  internal static func buildAndQuery(query: Query, filtersAnd: [FilterType], filtersOr: [FilterType]) -> Query {
    let query = Query(copy: query)
    let converter = FilterGroupConverter()
    let andGroup = FilterGroup.And(filters: filtersAnd)
    let (orFacetGroup, orNumericGroup, orTagGroup) = filtersOr.splitInDisjunctiveGroupsByFilterType()
    let filterGroups: [FilterGroupType] = [andGroup, orFacetGroup, orNumericGroup, orTagGroup].filter { !$0.filters.isEmpty }
    query.filters = converter.sql(filterGroups)
    return query
  }
  
  /// Builds "or" query for each facet
  /// - parameter query: source query
  /// - parameter filtersAnd: filters in conjunctive groups
  /// - parameter filtersOr: filters in disjunctive groups
  /// - parameter disjunctiveFacets: attributes of disjunctive facets
  /// - returns: list of "or" queries for disjunctive faceting

  internal static func buildOrQueries(query: Query, filtersAnd: [FilterType], filtersOr: [FilterType], disjunctiveFacets: Set<Attribute>) -> [Query] {
    return disjunctiveFacets.map { attribute in
      let query = Query(copy: query)
      query.facets = [attribute.name]
      query.attributesToRetrieve = []
      query.attributesToHighlight = []
      query.hitsPerPage = 0
      query.analytics = false
      let converter = FilterGroupConverter()
      let andGroup = FilterGroup.And(filters: filtersAnd)
      let (orFacetGroup, orNumericGroup, orTagGroup) = filtersOr.filter { !($0 is Filter.Facet && $0.attribute == attribute) }.splitInDisjunctiveGroupsByFilterType()
      let filterGroups: [FilterGroupType] = [andGroup, orFacetGroup, orNumericGroup, orTagGroup].filter { !$0.filters.isEmpty }
      query.filters = converter.sql(filterGroups)
      return query
    }
  }
  
}

extension Collection where Element == FilterType {
  
  func splitInDisjunctiveGroupsByFilterType() -> (FilterGroup.Or<Filter.Facet>, FilterGroup.Or<Filter.Numeric>, FilterGroup.Or<Filter.Tag>) {
    return (.init(filters: compactMap { $0 as? Filter.Facet }),
            .init(filters: compactMap { $0 as? Filter.Numeric }),
            .init(filters: compactMap { $0 as? Filter.Tag }))
  }
  
}

extension Collection {
  
  func partition(by predicate: (Element) -> Bool) -> (satisfying: [Element], rest: [Element]) {
    var satisfying: [Element] = []
    var rest: [Element] = []
    for element in self {
      if predicate(element) {
        satisfying.append(element)
      } else {
        rest.append(element)
      }
    }
    return (satisfying, rest)
  }
  
}

extension Collection {
  
  func all(predicate: (Element) -> Bool) -> Bool {
    return reduce(true) { $0 && predicate($1) }
  }
  
  func any(predicate: (Element) -> Bool) -> Bool {
    return reduce(false) { $0 || predicate($1) }
  }
  
}
