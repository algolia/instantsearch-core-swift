//
//  FacetSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FacetSearcher: Searcher, SearchResultObservable {
  
  public typealias SearchResult = FacetResults
  
  public var query: String? {
    didSet {
      guard oldValue != query else { return }
      onQueryChanged.fire(query)
    }
  }
  
  public let indexSearchData: IndexSearchData
  public let sequencer: Sequencer
  public var onQueryChanged: Observer<String?>
  public let isLoading: Observer<Bool>
  public let onResults: Observer<SearchResult>
  public let onError: Observer<Error>
  public var facetName: String
  public var requestOptions: RequestOptions?

  public var filterState: FilterState {
    return indexSearchData.filterState
  }
  
  public init(index: Index, query: Query = Query(), filterState: FilterState = FilterState(), facetName: String, requestOptions: RequestOptions? = nil) {
    self.indexSearchData = IndexSearchData(index: index, query: query, filterState: filterState)
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

    filterState.onChange.subscribePast(with: self) { _ in
      self.search()
    }
  }
  
  public func setQuery(text: String) {
    self.query = text
  }
  
  public func search() {
    
    indexSearchData.applyFilters()
    
    let operation = indexSearchData.index.searchForFacetValues(of: facetName, matching: query ?? "", requestOptions: requestOptions) { [weak self] (content, error) in
      
      guard let searcher = self else { return }
      
      let result: Result<FacetResults, Error> = searcher.transform(content: content, error: error)
      
      switch result {
      case .success(let results):
        searcher.onResults.fire(results)
        
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

extension FacetSearcher: SequencerDelegate {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
    isLoading.fire(hasPendingOperations)
  }
}
