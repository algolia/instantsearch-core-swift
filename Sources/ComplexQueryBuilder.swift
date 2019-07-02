//
//  ComplexQueryBuilder.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct ComplexQueryBuilder {
  
  public let query: Query
  public let filterGroups: [FilterGroupType]
  
  public let disjunctiveFacets: Set<Attribute>
  public var keepSelectedEmptyFacets: Bool
  
  public let hierarchicalAttributes: [Attribute]
  public let hierachicalFilters: [Filter.Facet]
  
  public let resultQueriesCount: Int = 1
  
  public var disjunctiveFacetingQueriesCount: Int {
    return disjunctiveFacets.count
  }
  
  public var hierarchicalFacetingQueriesCount: Int {
    return hierachicalFilters.isEmpty ? 0 : hierachicalFilters.count + 1
  }
  
  public var totalQueriesCount: Int {
    return resultQueriesCount + disjunctiveFacetingQueriesCount + hierarchicalFacetingQueriesCount
  }
  
  public init(query: Query,
              filterGroups: [FilterGroupType] = [],
              disjunctiveFacets: Set<Attribute> = [],
              hierarchicalAttributes: [Attribute] = [],
              hierachicalFilters: [Filter.Facet] = []) {
    self.query = query
    self.keepSelectedEmptyFacets = false
    self.filterGroups = filterGroups
    self.disjunctiveFacets = disjunctiveFacets
    self.hierarchicalAttributes = hierarchicalAttributes
    self.hierachicalFilters = hierachicalFilters
  }
  
  public func build() -> [Query] {
    
    let queryForResults = Query(copy: query)
    queryForResults.filters = FilterGroupConverter().sql(filterGroups)
    
    let disjunctiveFacetingQueries = DisjunctiveFacetingHelper.buildDisjunctiveFacetingQueries(query: query, filterGroups: filterGroups, disjunctiveFacets: disjunctiveFacets)
    
    let hierarchicalFacetingQueries = HierarchicalFacetingHelper.buildHierarchicalQueries(with: query,
                                                                                          filterGroups: filterGroups,
                                                                                          hierarchicalAttributes: hierarchicalAttributes,
                                                                                          hierachicalFilters: hierachicalFilters)
    
    return [queryForResults] + disjunctiveFacetingQueries + hierarchicalFacetingQueries
  }
  
  public func aggregate(_ results: [SearchResults]) throws -> SearchResults {
    
    guard var aggregatedResult = results.first else {
      throw Error.emptyResults
    }
    
    if results.count != totalQueriesCount {
      throw Error.queriesResultsCountMismatch(totalQueriesCount, results.count)
    }
    
    let resultsForDisjuncitveFaceting = results[1...disjunctiveFacetingQueriesCount]
    let resultsForHierarchicalFaceting = results[1 + disjunctiveFacetingQueriesCount..<totalQueriesCount]
    
    let facets = resultsForDisjuncitveFaceting.aggregateFacets()
    let facetStats = results.aggregateFacetStats()
    let hierarchicalFacets = resultsForHierarchicalFaceting.aggregateFacets()
    
    aggregatedResult.facetStats = facetStats.isEmpty ? nil : facetStats
    aggregatedResult.disjunctiveFacets = facets
    aggregatedResult.hierarchicalFacets = hierarchicalFacets.isEmpty ? nil : hierarchicalFacets
    aggregatedResult.areFacetsCountExhaustive = resultsForDisjuncitveFaceting.allSatisfy { $0.areFacetsCountExhaustive == true }
    
    if keepSelectedEmptyFacets {
      let filters = filterGroups.flatMap { $0.filters }
      aggregatedResult = DisjunctiveFacetingHelper.completeMissingFacets(in: aggregatedResult, disjunctiveFacets: disjunctiveFacets, filters: filters )
    }
    
    return aggregatedResult
    
  }
  
  public enum Error: Swift.Error {
    case emptyResults
    case queriesResultsCountMismatch(Int, Int)
  }
  
}
