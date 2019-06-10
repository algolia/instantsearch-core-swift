//
//  SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SingleIndexSearcher: Searcher, SearchResultObservable {
  
  public typealias SearchResult = SearchResults
  
  public var query: String? {

    set {
      let oldValue = indexSearchData.query.query
      guard oldValue != newValue else { return }
      indexSearchData.query.query = newValue
      indexSearchData.query.page = 0 // when new text changes, reset page to 0?
      onQueryChanged.fire(newValue)
    }
    
    get {
      return indexSearchData.query.query
    }

  }
  
  public let sequencer: Sequencer
  public var indexSearchData: IndexSearchData
  public let isLoading: Observer<Bool>
  public let onResults: Observer<SearchResults>
  public let onError: Observer<Error>
  public let onQueryChanged: Observer<String?>
  public var requestOptions: RequestOptions?
  
  public var filterState: FilterState {
    return indexSearchData.filterState
  }
  
  public var isDisjunctiveFacetingEnabled = true
  
  public init(index: Index,
              query: Query = .init(),
              filterState: FilterState = .init(),
              requestOptions: RequestOptions? = nil) {
    indexSearchData = IndexSearchData(index: index, query: query, filterState: filterState)
    self.requestOptions = requestOptions
    sequencer = Sequencer()
    isLoading = Observer()
    onResults = Observer()
    onError = Observer()
    onQueryChanged = Observer()
    sequencer.delegate = self
    onResults.retainLastData = true
    onError.retainLastData = false
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
  
  fileprivate func handle(_ value: [String: Any]?, _ error: Error?) {
    
    let result: Result<SearchResults, Error> = transform(content: value, error: error)
    
    switch result {
    case .success(let searchResults):
      onResults.fire(searchResults)
      
    case .failure(let error):
      onError.fire(error)
    }
    
  }
  
  public func search() {
  
    let operation: Operation
    
    if isDisjunctiveFacetingEnabled && indexSearchData.filterState.filters.isDisjunctiveFacetingAvailable() {
      let disjunctiveFacets = Array(indexSearchData.filterState.filters.getDisjunctiveFacetsAttributes()).map { $0.description }
      let refinements = indexSearchData.filterState.filters.getRawFacetFilters()
      indexSearchData.query.filters = nil
      operation = indexSearchData.index.searchDisjunctiveFaceting(indexSearchData.query, disjunctiveFacets: disjunctiveFacets, refinements: refinements, requestOptions: requestOptions) { [weak self] value, error in
        self?.handle(value, error)
      }
    } else {
      indexSearchData.applyFilters()
      operation = indexSearchData.index.search(indexSearchData.query, requestOptions: requestOptions) { [weak self] value, error in
        self?.handle(value, error)
      }
    }
    
    sequencer.orderOperation(operationLauncher: { return operation })
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}

extension SingleIndexSearcher: SequencerDelegate {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
    isLoading.fire(hasPendingOperations)
  }
}
