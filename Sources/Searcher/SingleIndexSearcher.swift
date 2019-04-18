//
//  SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SingleIndexSearcher<Record: Codable>: Searcher, SearchResultObservable {
  
  public typealias SearchResult = (QueryMetadata, Result<SearchResults<Record>, Error>)
  
  public let sequencer: Sequencer
  public let isLoading = Observer<Bool>()
  public let indexSearchData: IndexSearchData
  public let onSearchResults = Observer<SearchResult>()
  
  public var applyDisjunctiveFacetingWhenNecessary = true
  
  public init(index: Index, query: Query = .init(), filterState: FilterState = .init()) {
    self.indexSearchData = IndexSearchData(index: index, query: query, filterState: filterState)
    sequencer = Sequencer()
    sequencer.delegate = self
    onSearchResults.retainLastData = true
    isLoading.retainLastData = true
  }
  
  public convenience init(indexSearchData: IndexSearchData) {
    self.init(index: indexSearchData.index, query: indexSearchData.query, filterState: indexSearchData.filterState)
  }
  
  public func setQuery(text: String) {
    self.indexSearchData.query.query = text
  }
  
  fileprivate func handle(_ value: [String: Any]?, _ error: Error?, _ queryMetadata: QueryMetadata) {
    let result: Result<SearchResults<Record>, Error> = self.transform(content: value, error: error)
    self.onSearchResults.fire((queryMetadata, result))
  }
  
  public func search(requestOptions: RequestOptions? = nil) {
    // TODO: weak self...
    sequencer.orderOperation {
      let queryMetadata = QueryMetadata(query: indexSearchData.query)
      
      if applyDisjunctiveFacetingWhenNecessary && indexSearchData.filterState.filters.isDisjunctiveFacetingAvailable() {
        let disjunctiveFacets = Array(indexSearchData.filterState.filters.getDisjunctiveFacetsAttributes()).map { $0.description }
        let refinements = indexSearchData.filterState.filters.getRawFacetFilters()
        
        return indexSearchData.index.searchDisjunctiveFaceting(indexSearchData.query, disjunctiveFacets: disjunctiveFacets, refinements: refinements, requestOptions: requestOptions) { value, error in
          self.handle(value, error, queryMetadata)
        }
      } else {
        indexSearchData.applyFilters()
        return indexSearchData.index.search(indexSearchData.query, requestOptions: requestOptions) { value, error in
          self.handle(value, error, queryMetadata)
        }
      }
    }
  }
  
}
