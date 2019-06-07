//
//  MultiIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class MultiIndexSearcher: Searcher, SearchResultObservable {
  
  public typealias SearchResult = MultiSearchResults
  
  public var query: String? {
    
    set {
      let oldValue = indexSearchDatas.first?.query.query
      guard oldValue != newValue else { return }
      indexSearchDatas.forEach { $0.query.query = newValue }
      indexSearchDatas.forEach { $0.query.page = 0 }
      onQueryChanged.fire(newValue)
    }
    
    get {
      return indexSearchDatas.first?.query.query
    }

  }
  
  public let client: Client
  public let indexSearchDatas: [IndexSearchData]
  public let sequencer: Sequencer
  public let isLoading: Observer<Bool>
  public let onQueryChanged: Observer<String?>
  public let onResults: Observer<SearchResult>
  public let onError: Observer<Error>
  public var applyDisjunctiveFacetingWhenNecessary = true
  public var requestOptions: RequestOptions?
  internal var pageLoaders: [PageLoaderProxy]
  
  public init(client: Client,
              indexSearchDatas: [IndexSearchData],
              requestOptions: RequestOptions? = nil) {
    
    self.client = client
    self.indexSearchDatas = indexSearchDatas
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
    
    self.pageLoaders = indexSearchDatas.map { isd in
      return PageLoaderProxy(setPage: { isd.query.page = UInt($0) }, launchSearch: self.search)
    }

  }
  
  public func search() {
    
    indexSearchDatas.forEach { $0.applyFilters() }
    
    let indexQueries = indexSearchDatas.map(IndexQuery.init(indexSearchData:))
    
    let operation = client.multipleQueries(indexQueries, requestOptions: requestOptions) { [weak self] (content, error) in
      
      guard let searcher = self else { return }
      
      let result: Result<MultiSearchResults, Error> = searcher.transform(content: content, error: error)
      
      switch result {
      case .success(let searchResults):
        searcher.onResults.fire(searchResults)
        
      case .failure(let error):
        searcher.onError.fire(error)
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

extension MultiIndexSearcher: SequencerDelegate {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
    isLoading.fire(hasPendingOperations)
  }
}
