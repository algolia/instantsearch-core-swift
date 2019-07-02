//
//  HierarchicalFacetingHelper.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class HierarchicalFacetingHelper {
  
  /// Blocks instantiating this class
  
  private init() {}
  
  public static func buildHierarchicalQueries(with query: Query,
                                              filterGroups: [FilterGroupType],
                                              hierarchicalAttributes: [Attribute],
                                              hierachicalFilters: [Filter.Facet]) -> [Query] {
    
    // An empty hierarchical offset in the beggining is added to create
    // The first request in the list returning search results
    
    let offsetHierachicalFilters: [Filter.Facet?] = [.none] + hierachicalFilters
    
    let queriesForHierarchicalFacets = zip(hierarchicalAttributes, offsetHierachicalFilters)
      .map { arguments -> Query in
        let (attribute, hierarchicalFilter) = arguments
        
        var outputFilterGroups = filterGroups
        
        if let currentHierarchicalFilter = hierarchicalFilter {
          outputFilterGroups.append(FilterGroup.And(filters: [currentHierarchicalFilter], name: "_hierarchical"))
        }
        
        if let appliedHierachicalFacet = hierachicalFilters.last {
          outputFilterGroups = outputFilterGroups.map { group in
            guard let andGroup = group as? FilterGroup.And else {
              return group
            }
            let filtersMinusHierarchicalFacet = andGroup.filters.filter { ($0 as? Filter.Facet) != appliedHierachicalFacet }
            return FilterGroup.And(filters: filtersMinusHierarchicalFacet, name: andGroup.name)
          }
        }
        
        let query = Query(copy: query)
        query.requestOnlyFacets()
        query.facets = [attribute.name]
        query.filters = FilterGroupConverter().sql(outputFilterGroups)
        return query
        
    }
    
    return queriesForHierarchicalFacets
    
  }
  
}
