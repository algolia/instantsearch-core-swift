//
//  MultiIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/** An entity performing search queries targeting multiple indices.
*/

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
  
  /// `Client` instance containing indices in which search will be performed
  public let client: Client
  
  /// List of  index & query tuples
  public let indexQueryStates: [IndexQueryState]
  
  public let isLoading: Observer<Bool>
  
  public let onQueryChanged: Observer<String?>
  
  public let onResults: Observer<SearchResult>
  
  /// Triggered when an error occured during search query execution
  /// - Parameter: a tuple of query and error
  public let onError: Observer<([Query], Error)>
  
  /// Custom request options
  public var requestOptions: RequestOptions?
  
  /// Sequencer which orders and debounce redundant search operations
  internal let sequencer: Sequencer

  /// Helpers for separate pagination management
  internal var pageLoaders: [PageLoaderProxy]
  
  /**
   - Parameters:
   - appID: Application ID
   - apiKey: API Key
   - indexNames: List of the indices names in which search will be performed
   - requestOptions: Custom request options. Default is nil.
   */
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
  
  /**
   - Parameters:
   - appID: Application ID
   - apiKey: API Key
   - indexNames: List of the indices names in which search will be performed
   - requestOptions: Custom request options. Default is `nil`.
   */

  public convenience init(client: Client,
                          indices: [Index],
                          requestOptions: RequestOptions? = nil) {
    let indexQueryStates = indices.map { IndexQueryState(index: $0, query: .init()) }
    self.init(client: client,
              indexQueryStates: indexQueryStates,
              requestOptions: requestOptions)
  }
  
  /**
   - Parameters:
   - appID: Application ID
   - apiKey: API Key
   - indexQueryStates: List of the instances of IndexQueryStates encapsulating index value in which search will be performed and a correspondant Query instance
   - requestOptions: Custom request options. Default is nil.
   */
  
  public init(client: Client,
              indexQueryStates: [IndexQueryState],
              requestOptions: RequestOptions? = nil) {
    
    self.client = client
    self.indexQueryStates = indexQueryStates
    self.requestOptions = requestOptions
    self.pageLoaders = []
    
    sequencer = .init()
    onQueryChanged = .init()
    isLoading = .init()
    onResults = .init()
    onError = .init()
    
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

internal extension MultiIndexSearcher {
  
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
