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
  
  public let sequencer: Sequencer
  public var indexQueryState: IndexQueryState {
    didSet {
      if oldValue.index != indexQueryState.index {
        onIndexChanged.fire(indexQueryState.index)
      }
    }
  }
  public let isLoading: Observer<Bool>
  public let onResults: Observer<SearchResults>
  public let onError: Observer<(Query, Error)>
  public let onQueryChanged: Observer<String?>
  public let onIndexChanged: Observer<Index>
  public var requestOptions: RequestOptions?
  public weak var disjunctiveFacetingDelegate: DisjunctiveFacetingDelegate?
  public weak var hierarchicalFacetingDelegate: HierarchicalDelegate?
  
  public var isDisjunctiveFacetingEnabled = true
  
  public convenience init(appID: String,
                          apiKey: String,
                          indexName: String,
                          query: Query = .init(),
                          requestOptions: RequestOptions? = nil) {
    let client = Client(appID: appID, apiKey: apiKey)
    let index = client.index(withName: indexName)
    self.init(index: index, query: query, requestOptions: requestOptions)
  }
  
  public init(index: Index,
              query: Query = .init(),
              requestOptions: RequestOptions? = nil) {
    indexQueryState = IndexQueryState(index: index, query: query)
    self.requestOptions = requestOptions
    sequencer = Sequencer()
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
  
  public convenience init(indexQueryState: IndexQueryState,
                          requestOptions: RequestOptions? = nil) {
    self.init(index: indexQueryState.index,
              query: indexQueryState.query,
              requestOptions: requestOptions)
  }
  
  fileprivate func handle(for query: Query) -> (_ value: [String: Any]?, _ error: Error?) -> Void {
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
  
  fileprivate func handleDisjunctiveFacetingResponse(for queryBuilder: QueryBuilder) -> (_ value: [String: Any]?, _ error: Error?) -> Void {
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
  
  public func search() {
  
    let query = Query(copy: indexQueryState.query)
    
    let operation: Operation

    if isDisjunctiveFacetingEnabled {
      let filterGroups = disjunctiveFacetingDelegate?.toFilterGroups() ?? []
      let hierarchicalAttributes = hierarchicalFacetingDelegate?.hierarchicalAttributes ?? []
      let hierarchicalFilters = hierarchicalFacetingDelegate?.hierarchicalFilters ?? []
      var queriesBuilder = QueryBuilder(query: query, filterGroups: filterGroups, hierarchicalAttributes: hierarchicalAttributes, hierachicalFilters: hierarchicalFilters)
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

public protocol DisjunctiveFacetingDelegate: class, FilterGroupsConvertible {
  
  var disjunctiveFacetsAttributes: Set<Attribute> { get }
  
}

public extension SingleIndexSearcher {
  
  func connectFilterState(_ filterState: FilterState) {
    
    disjunctiveFacetingDelegate = filterState
    hierarchicalFacetingDelegate = filterState
    
<<<<<<< HEAD
    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.indexQueryState.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      self?.search()
=======
    filterState.onChange.subscribePast(with: self) { searcher, _ in
      searcher.indexSearchData.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      searcher.search()
>>>>>>> Adding strongly typed observer to signal
    }
    
  }
  
}
