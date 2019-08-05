//
//  FacetSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/** An entity performing search for facet values
 */

public class FacetSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = FacetResults
  
  public var query: String? {
    didSet {
      guard oldValue != query else { return }
      onQueryChanged.fire(query)
    }
  }
  
  /// Current tuple of index and query
  public let indexQueryState: IndexQueryState
  
  public var onQueryChanged: Observer<String?>
  
  public let isLoading: Observer<Bool>
  
  public let onResults: Observer<SearchResult>
  
  /// Triggered when an error occured during search query execution
  /// - Parameter: a tuple of query text and error
  public let onError: Observer<(String, Error)>
  
  /// Name of facet attribute for which the values will be searched
  public var facetName: String
  
  /// Custom request options
  public var requestOptions: RequestOptions?
  
  /// Sequencer which orders and debounce redundant search operations
  internal let sequencer: Sequencer

  /**
   - Parameters:
   - appID: Application ID
   - apiKey: API Key
   - indexName: Name of the index in which search will be performed
   - facetName: Name of facet attribute for which the values will be searched
   - query: Instance of Query. By default a new empty instant of Query will be created.
   - requestOptions: Custom request options. Default is `nil`.
   */
  public convenience init(appID: String,
                          apiKey: String,
                          indexName: String,
                          facetName: String,
                          query: Query = .init(),
                          requestOptions: RequestOptions? = nil) {
    let client = Client(appID: appID, apiKey: apiKey)
    let index = client.index(withName: indexName)
    self.init(index: index,
              facetName: facetName,
              query: query,
              requestOptions: requestOptions)
  }
  
  /**
   - Parameters:
   - index: Index value in which search will be performed
   - facetName: Name of facet attribute for which the values will be searched
   - query: Instance of Query. By default a new empty instant of Query will be created.
   - requestOptions: Custom request options. Default is `nil`.
   */
  public init(index: Index,
              facetName: String,
              query: Query = .init(),
              requestOptions: RequestOptions? = nil) {
    self.indexQueryState = IndexQueryState(index: index, query: query)
    self.isLoading = .init()
    self.onQueryChanged = .init()
    self.onResults = .init()
    self.onError = .init()
    self.facetName = facetName
    self.sequencer = .init()
    self.requestOptions = requestOptions
    sequencer.delegate = self
    onResults.retainLastData = true
    isLoading.retainLastData = true
    updateClientUserAgents()
  }
  
  public func search() {
    
    let query = self.query ?? ""
    let operation = indexQueryState.index.searchForFacetValues(of: facetName, matching: query, requestOptions: requestOptions) { [weak self] (content, error) in
      
      guard let searcher = self else { return }
      
      let result: Result<FacetResults, Error> = searcher.transform(content: content, error: error)
      
      switch result {
      case .success(let results):
        searcher.onResults.fire(results)
        
      case .failure(let error):
        searcher.onError.fire((query, error))
      }
    }
    
    sequencer.orderOperation(operationLauncher: { return operation })
    
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}
