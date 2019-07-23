//
//  MultiIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class MultiIndexSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = MultiSearchResults
  
  public var query: String? {
    
    set {
      let oldValue = indexQueryStates.first?.query.query
      guard oldValue != newValue else { return }
      indexQueryStates.forEach { $0.query.query = newValue }
      indexQueryStates.forEach { $0.query.page = 0 }
      onQueryChanged.fire(newValue)
    }
    
    get {
      return indexQueryStates.first?.query.query
    }

  }
  
  public let client: Client
  public let indexQueryStates: [IndexQueryState]
  public let sequencer: Sequencer
  public let isLoading: Observer<Bool>
  public let onQueryChanged: Observer<String?>
  public let onResults: Observer<SearchResult>
  public let onError: Observer<([Query], Error)>
  public var applyDisjunctiveFacetingWhenNecessary = true
  public var requestOptions: RequestOptions?
  internal var pageLoaders: [PageLoaderProxy]
  
  public convenience init(appID: String,
                          apiKey: String,
                          indexNames: [String],
                          requestOptions: RequestOptions? = nil) {
    let client = Client(appID: appID, apiKey: apiKey)
    let indices = indexNames.map(client.index(withName:))
    let indexQueryStates = indices.map { IndexQueryState(index: $0, query: .init()) }
    self.init(client: client,
              indexQueryStates: indexQueryStates,
              requestOptions: requestOptions)
  }
  
  public convenience init(client: Client,
                          indices: [Index],
                          requestOptions: RequestOptions? = nil) {
    let indexQueryStates = indices.map { IndexQueryState(index: $0, query: .init()) }
    self.init(client: client,
              indexQueryStates: indexQueryStates,
              requestOptions: requestOptions)
  }
  
  public init(client: Client,
              indexQueryStates: [IndexQueryState],
              requestOptions: RequestOptions? = nil) {
    
    self.client = client
    self.indexQueryStates = indexQueryStates
    self.requestOptions = requestOptions
    self.pageLoaders = []
    
    sequencer = Sequencer()
    onQueryChanged = Observer()
    isLoading = Observer()
    onResults = Observer()
    onError = Observer()
    
    sequencer.delegate = self
    onResults.retainLastData = true
    isLoading.retainLastData = true
    updateClientUserAgents()
    
    self.pageLoaders = indexQueryStates.map { isd in
      return PageLoaderProxy(setPage: { isd.query.page = UInt($0) }, launchSearch: self.search)
    }

  }
  
  public func search() {
    
    let indexQueries = indexQueryStates.map(IndexQuery.init(indexQueryState:))
    let queries = indexQueryStates.map { $0.query.copy() as! Query }
    let operation = client.multipleQueries(indexQueries, requestOptions: requestOptions) { [weak self] (content, error) in
      
      guard let searcher = self else { return }
      
      let result: Result<MultiSearchResults, Error> = searcher.transform(content: content, error: error)
      
      switch result {
      case .success(let searchResults):
        searcher.onResults.fire(searchResults)
        
      case .failure(let error):
        searcher.onError.fire((queries, error))
      }
      
    }
    
    sequencer.orderOperation(operationLauncher: { return operation })
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}

extension MultiIndexSearcher {
  
  class PageLoaderProxy: PageLoadable {
    
    let setPage: (Int) -> Void
    let launchSearch: () -> Void
    
    init(setPage: @escaping (Int) -> Void, launchSearch: @escaping () -> Void) {
      self.setPage = setPage
      self.launchSearch = launchSearch
    }
    
    func loadPage(atIndex pageIndex: Int) {
      setPage(pageIndex)
      launchSearch()
    }
    
  }
  
}

//TODO: do a proper connection between each query and filterState

extension MultiIndexSearcher {
  
  func connectFilterState(_ filterState: FilterState, withQueryAtIndex index: Int) {
    filterState.onChange.subscribe(with: self) { searcher, filters in
      searcher.indexSearchDatas[index].query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      searcher.search()
    }
  }
  
}
