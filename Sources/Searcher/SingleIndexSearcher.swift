//
//  SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SingleIndexSearcher<Record: Codable>: Searcher, SearchResultObservable {
  
  public typealias SearchResult = (Query, FiltersReadable, Result<SearchResults<Record>, Error>)
  
  public var query: String? {

    set {
      let oldValue = indexSearchData.query.query
      if oldValue != newValue {
        indexSearchData.query.query = newValue
        onQueryChanged.fire(newValue)
      }
    }
    
    get {
      return indexSearchData.query.query
    }

  }
  
  public let sequencer: Sequencer
  public let isLoading = Observer<Bool>()
  public let indexSearchData: IndexSearchData
  public let onResultsChanged = Observer<SearchResult>()
  public let onQueryChanged = Observer<String?>()
  public var requestOptions: RequestOptions?
  
  public var filterState: FilterState {
    return indexSearchData.filterState
  }
  
  public var isDisjunctiveFacetingEnabled = true
  
  public init(index: Index,
              query: Query = .init(),
              filterState: FilterState = .init(),
              requestOptions: RequestOptions? = nil) {
    self.indexSearchData = IndexSearchData(index: index, query: query, filterState: filterState)
    self.requestOptions = requestOptions
    sequencer = Sequencer()
    sequencer.delegate = self
    onResultsChanged.retainLastData = true
    isLoading.retainLastData = true

    filterState.onChange.subscribePast(with: self) { _ in
      self.search()
    }
  }
  
  public convenience init(indexSearchData: IndexSearchData,
                          requestOptions: RequestOptions? = nil) {
    self.init(index: indexSearchData.index,
              query: indexSearchData.query,
              filterState: indexSearchData.filterState,
              requestOptions: requestOptions)
  }
  
  public func setQuery(text: String) {
    self.indexSearchData.query.query = text
    self.indexSearchData.query.page = 0 // when new text changes, reset page to 0?
    onQueryChanged.fire(text)
  }
  
  fileprivate func handle(_ value: [String: Any]?, _ error: Error?, _ query: Query, _ filterState: FiltersReadable) {
    let result: Result<SearchResults<Record>, Error> = self.transform(content: value, error: error)
    self.onResultsChanged.fire((query, filterState, result))
  }
  
  public func search() {
    // TODO: weak self...
  
    sequencer.orderOperation {
      let query = indexSearchData.query
      let filterState = indexSearchData.filterState.filters
      
      if isDisjunctiveFacetingEnabled && indexSearchData.filterState.filters.isDisjunctiveFacetingAvailable() {
        let disjunctiveFacets = Array(indexSearchData.filterState.filters.getDisjunctiveFacetsAttributes()).map { $0.description }
        let refinements = indexSearchData.filterState.filters.getRawFacetFilters()
        indexSearchData.query.filters = nil
        return indexSearchData.index.searchDisjunctiveFaceting(indexSearchData.query, disjunctiveFacets: disjunctiveFacets, refinements: refinements, requestOptions: requestOptions) { value, error in
          self.handle(value, error, query, filterState)
        }
      } else {
        indexSearchData.applyFilters()
        return indexSearchData.index.search(indexSearchData.query, requestOptions: requestOptions) { value, error in
          self.handle(value, error, query, filterState)
        }
      }
    }
  }
  
}
