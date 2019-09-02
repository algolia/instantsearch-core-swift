//
//  PlacesSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class PlacesSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = SearchResults
  
  public var query: String? {
    
    get {
      return placesQuery.query
    }
    
    set {
      let oldValue = placesQuery.query
      guard oldValue != newValue else { return }
      placesQuery.query = newValue
      onQueryChanged.fire(newValue)
    }

  }
  
  public var placesQuery: PlacesQuery
  
  public var onQueryChanged: Observer<String?>
  
  public let isLoading: Observer<Bool>

  public let onResults: Observer<SearchResult>

  /// Triggered when an error occured during search query execution
  /// - Parameter: a tuple of query text and error
  public let onError: Observer<(String, Error)>
  
  /// Sequencer which orders and debounce redundant search operations
  internal let sequencer: Sequencer

  internal let placesClient: PlacesClient
  
  public convenience init(appID: String,
                          apiKey: String,
                          query: PlacesQuery = .init()) {
    let client = PlacesClient(appID: appID, apiKey: apiKey)
    self.init(client: client, query: query)
  }
  
  public init(client: PlacesClient, query: PlacesQuery = .init()) {
    self.placesClient = client
    self.placesQuery = query
    self.isLoading = .init()
    self.onQueryChanged = .init()
    self.onResults = .init()
    self.onError = .init()
    self.sequencer = .init()
    placesQuery.language = "en"
    sequencer.delegate = self
    onResults.retainLastData = true
    isLoading.retainLastData = true
  }
  
  public func search() {
    
    let operation = placesClient.search(placesQuery) { [weak self] (content, error) in
      guard let searcher = self else { return }
      let result: Result<SearchResults, Error> = searcher.transform(content: content, error: error)
      
      switch result {
      case .success(let results):
        searcher.onResults.fire(results)
        
      case .failure(let error):
        let query = searcher.placesQuery.query ?? ""
        searcher.onError.fire((query, error))
      }
    }
    
    sequencer.orderOperation {
      return operation
    }
    
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}
