//
//  SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/** An entity performing search queries targeting one index
*/

public class SingleIndexSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = SearchResults
  
  public var query: String? {

    set {
      let oldValue = indexQueryState.query.query
      guard oldValue != newValue else { return }
      indexQueryState.query.query = newValue
      indexQueryState.query.page = 0
      onQueryChanged.fire(newValue)
    }
    
    get {
      return indexQueryState.query.query
    }

  }
  
  /// Current index & query tuple
  public var indexQueryState: IndexQueryState {
    didSet {
      if oldValue.index != indexQueryState.index {
        onIndexChanged.fire(indexQueryState.index)
      }
    }
  }
  
  public let isLoading: Observer<Bool>
  
  public let onResults: Observer<SearchResults>
  
  /// Triggered when an error occured during search query execution
  /// - Parameter: a tuple of query and error
  public let onError: Observer<(Query, Error)>
  
  public let onQueryChanged: Observer<String?>
  
  /// Triggered when an index of Searcher changed
  /// - Parameter: equals to a new index value
  public let onIndexChanged: Observer<Index>
  
  /// Custom request options
  public var requestOptions: RequestOptions?
  
  /// Delegate providing a necessary information for disjuncitve faceting
  public weak var disjunctiveFacetingDelegate: DisjunctiveFacetingDelegate?
  
  /// Delegate providing a necessary information for hierarchical faceting
  public weak var hierarchicalFacetingDelegate: HierarchicalFacetingDelegate?
  
  /// Flag defining if disjunctive faceting is enabled
  /// - Default value: true
  public var isDisjunctiveFacetingEnabled = true
  
  /// Sequencer which orders and debounce redundant search operations
  internal let sequencer: Sequencer
  
  /**
   - Parameters:
      - appID: Application ID
      - apiKey: API Key
      - indexName: Name of the index in which search will be performed
      - query: Instance of Query. By default a new empty instant of Query will be created.
      - requestOptions: Custom request options. Default is `nil`.
  */
  public convenience init(appID: String,
                          apiKey: String,
                          indexName: String,
                          query: Query = .init(),
                          requestOptions: RequestOptions? = nil) {
    let client = Client(appID: appID, apiKey: apiKey)
    let index = client.index(withName: indexName)
    self.init(index: index, query: query, requestOptions: requestOptions)
  }
  
  /**
   - Parameters:
      - index: Index value in which search will be performed
      - query: Instance of Query. By default a new empty instant of Query will be created.
      - requestOptions: Custom request options. Default is nil.
  */
  public init(index: Index,
              query: Query = .init(),
              requestOptions: RequestOptions? = nil) {
    indexQueryState = .init(index: index, query: query)
    self.requestOptions = requestOptions
    sequencer = .init()
    isLoading = .init()
    onResults = .init()
    onError = .init()
    onQueryChanged = .init()
    onIndexChanged = .init()
    sequencer.delegate = self
    onResults.retainLastData = true
    onError.retainLastData = false
    isLoading.retainLastData = true
    updateClientUserAgents()
    
  }
  
  /**
   - Parameters:
      - indexQueryState: Instance of `IndexQueryState` encapsulating index value in which search will be performed and a `Query` instance.
      - requestOptions: Custom request options. Default is nil.
   */
  public convenience init(indexQueryState: IndexQueryState,
                          requestOptions: RequestOptions? = nil) {
    self.init(index: indexQueryState.index,
              query: indexQueryState.query,
              requestOptions: requestOptions)
  }
  
  public func search() {
  
    let query = Query(copy: indexQueryState.query)
    
    let operation: Operation

    if isDisjunctiveFacetingEnabled {
      let filterGroups = disjunctiveFacetingDelegate?.toFilterGroups() ?? []
      let hierarchicalAttributes = hierarchicalFacetingDelegate?.hierarchicalAttributes ?? []
      let hierarchicalFilters = hierarchicalFacetingDelegate?.hierarchicalFilters ?? []
      var queriesBuilder = QueryBuilder(query: query,
                                        filterGroups: filterGroups,
                                        hierarchicalAttributes: hierarchicalAttributes,
                                        hierachicalFilters: hierarchicalFilters)
      queriesBuilder.keepSelectedEmptyFacets = true
      let queries = queriesBuilder.build().map { IndexQuery(index: indexQueryState.index, query: $0) }
      operation = indexQueryState.index.client.multipleQueries(queries, requestOptions: requestOptions, completionHandler: handleDisjunctiveFacetingResponse(for: queriesBuilder))
    } else {
      operation = indexQueryState.index.search(query, requestOptions: requestOptions, completionHandler: handle(for: query))
    }
    
    sequencer.orderOperation(operationLauncher: { return operation })
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}

private extension SingleIndexSearcher {
  
  func handle(for query: Query) -> (_ value: [String: Any]?, _ error: Error?) -> Void {
    return { [weak self] value, error in
      let result = Result<SearchResults, Error>(rawValue: value, error: error)
      
      switch result {
      case .success(let searchResults):
        self?.onResults.fire(searchResults)
        
      case .failure(let error):
        self?.onError.fire((query, error))
      }
      
    }
  }
  
  func handleDisjunctiveFacetingResponse(for queryBuilder: QueryBuilder) -> (_ value: [String: Any]?, _ error: Error?) -> Void {
    return { [weak self] value, error in
      let result = Result<MultiSearchResults, Error>(rawValue: value, error: error)
      
      switch result {
      case .failure(let error):
        self?.onError.fire((queryBuilder.query, error))
        
      case .success(let results):
        do {
          let result = try queryBuilder.aggregate(results.searchResults)
          self?.onResults.fire(result)
        } catch let error {
          self?.onError.fire((queryBuilder.query, error))
        }
      }
    }
  }
  
}
