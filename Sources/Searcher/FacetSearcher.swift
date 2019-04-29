//
//  FacetSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FacetSearcher: Searcher, SearchResultObservable {
  
  public typealias SearchResult = (QueryMetadata, Result<FacetResults, Error>)
  
  public let indexSearchData: IndexSearchData
  public let sequencer: Sequencer
  public let onResultsChanged = Observer<SearchResult>()
  public let isLoading = Observer<Bool>()
  public var facetName: String
  public var text: String
  
  public init(index: Index, query: Query, filterState: FilterState, facetName: String, text: String) {
    self.indexSearchData = IndexSearchData(index: index, query: query, filterState: filterState)
    self.facetName = facetName
    self.text = text
    self.sequencer = Sequencer()
    sequencer.delegate = self
    onResultsChanged.retainLastData = true
    isLoading.retainLastData = true
    
    filterState.onChange.subscribe(with: self) { _ in
      self.search()
    }
  }
  
  public func setQuery(text: String) {
    self.text = text
  }
  
  public func search(requestOptions: RequestOptions? = nil) {
    
    indexSearchData.applyFilters()
    
    let metadata = QueryMetadata(query: indexSearchData.query)
    
    sequencer.orderOperation {
      return self.indexSearchData.index.searchForFacetValues(of: facetName, matching: text, requestOptions: requestOptions) { (content, error) in
        let result: Result<FacetResults, Error> = self.transform(content: content, error: error)
        self.onResultsChanged.fire((metadata, result))
      }
    }
    
  }
  
}
