//
//  SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SingleIndexSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = SearchResults
  
  public var query: String? {

    set {
      let oldValue = indexSearchData.query.query
      guard oldValue != newValue else { return }
      indexSearchData.query.query = newValue
      indexSearchData.query.page = 0
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
  public let onError: Observer<(Query, Error)>
  public let onQueryChanged: Observer<String?>
  public var requestOptions: RequestOptions?
  public weak var disjunctiveFacetingDelegate: DisjunctiveFacetingDelegate?
  
  public var isDisjunctiveFacetingEnabled = true
  
  public init(index: Index,
              query: Query = .init(),
              requestOptions: RequestOptions? = nil) {
    indexSearchData = IndexSearchData(index: index, query: query)
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
  }
  
  public convenience init(indexSearchData: IndexSearchData,
                          requestOptions: RequestOptions? = nil) {
    self.init(index: indexSearchData.index,
              query: indexSearchData.query,
              requestOptions: requestOptions)
  }
  
  fileprivate func handle(_ value: [String: Any]?, _ error: Error?, for query: Query) {
    
    let result: Result<SearchResults, Error> = transform(content: value, error: error)
    
    switch result {
    case .success(let searchResults):
      onResults.fire(searchResults)
      
    case .failure(let error):
      onError.fire((query, error))
    }
    
  }
  
  public func search() {
  
    let operation: Operation

    if
      let disjunctiveFacetingDelegate = disjunctiveFacetingDelegate,
      !disjunctiveFacetingDelegate.disjunctiveFacetsAttributes.isEmpty,
      isDisjunctiveFacetingEnabled
    {
      let disjunctiveFacets = Array(disjunctiveFacetingDelegate.disjunctiveFacetsAttributes).map { $0.description }
      let refinements = disjunctiveFacetingDelegate.facetFilters
      indexSearchData.query.filters = nil
      let query = indexSearchData.query.copy() as! Query
      operation = indexSearchData.index.searchDisjunctiveFaceting(indexSearchData.query, disjunctiveFacets: disjunctiveFacets, refinements: refinements, requestOptions: requestOptions) { [weak self] value, error in
        self?.handle(value, error, for: query)
      }
    } else {
      let query = indexSearchData.query.copy() as! Query
      operation = indexSearchData.index.search(indexSearchData.query, requestOptions: requestOptions) { [weak self] value, error in
        self?.handle(value, error, for: query)
      }
    }
    
    sequencer.orderOperation(operationLauncher: { return operation })
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}

public protocol DisjunctiveFacetingDelegate: class {
  
  var disjunctiveFacetsAttributes: [String] { get }
  var facetFilters: [String: [String]] { get }
  
}

public extension SingleIndexSearcher {
  
  func connectFilterState(_ filterState: FilterState) {
    
    disjunctiveFacetingDelegate = filterState
    
    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.indexSearchData.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      self?.search()
    }
    
  }
  
}
