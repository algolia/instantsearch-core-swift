//
//  FacetSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FacetSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = FacetResults
  
  public var query: String? {
    didSet {
      guard oldValue != query else { return }
      onQueryChanged.fire(query)
    }
  }
  
  public let indexQueryState: IndexQueryState
  public let sequencer: Sequencer
  public var onQueryChanged: Observer<String?>
  public let isLoading: Observer<Bool>
  public let onResults: Observer<SearchResult>
  public let onError: Observer<(String, Error)>
  public var facetName: String
  public var requestOptions: RequestOptions?

  public convenience init(appID: String,
                          apiKey: String,
                          indexName: String,
                          facetName: String,
                          query: Query = .init(),
                          requestOptions: RequestOptions? = nil) {
    let client = Client(appID: appID, apiKey: apiKey)
    let index = client.index(withName: indexName)
    self.init(index: index,
              query: query,
              facetName: facetName,
              requestOptions: requestOptions)
  }
  
  public init(index: Index,
              query: Query = .init(),
              facetName: String,
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

public extension FacetSearcher {
  
  func connectFilterState(_ filterState: FilterState) {
    filterState.onChange.subscribePast(with: self) { searcher, filterState in
      searcher.indexQueryState.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      searcher.search()
    }
  }
  
}
