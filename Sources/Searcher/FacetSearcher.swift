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

  public init(index: Index, query: Query = .init(), facetName: String, requestOptions: RequestOptions? = nil) {
    self.indexQueryState = IndexQueryState(index: index, query: query)
    self.isLoading = Observer()
    self.onQueryChanged = Observer()
    self.onResults = Observer()
    self.onError = Observer()
    self.facetName = facetName
    self.sequencer = Sequencer()
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
    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.indexQueryState.query.filters = FilterGroupConverter().sql(filterState.toFilterGroups())
      self?.search()
    }
  }
  
}
