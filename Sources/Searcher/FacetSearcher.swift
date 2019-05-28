//
//  FacetSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class FacetSearcher: Searcher, SearchResultObservable {
  
  public typealias SearchResult = Result<FacetResults, Error>
  
  public var query: String? {
    didSet {
      if oldValue != query {
        onQueryChanged.fire(query)
      }
    }
  }
  
  public let indexSearchData: IndexSearchData
  public let sequencer: Sequencer
  public let onResultsChanged = Observer<SearchResult>()
  public var onQueryChanged = Observer<String?>()
  public let isLoading = Observer<Bool>()
  public var facetName: String
  public var text: String
  public var requestOptions: RequestOptions?

  public var filterState: FilterState {
    return indexSearchData.filterState
  }
  
  public init(index: Index, query: Query = Query(), filterState: FilterState = FilterState(), facetName: String, text: String = "", requestOptions: RequestOptions? = nil) {
    self.indexSearchData = IndexSearchData(index: index, query: query, filterState: filterState)
    self.facetName = facetName
    self.text = text
    self.sequencer = Sequencer()
    self.requestOptions = requestOptions
    sequencer.delegate = self
    onResultsChanged.retainLastData = true
    isLoading.retainLastData = true

    filterState.onChange.subscribePast(with: self) { _ in
      self.search()
    }
  }
  
  public func setQuery(text: String) {
    self.text = text
    onQueryChanged.fire(text)
  }
  
  public func search() {
    
    indexSearchData.applyFilters()
        
    sequencer.orderOperation {
      return self.indexSearchData.index.searchForFacetValues(of: facetName, matching: text, requestOptions: requestOptions) { (content, error) in
        let result: Result<FacetResults, Error> = self.transform(content: content, error: error)
        self.onResultsChanged.fire(result)
      }
    }
    
  }
  
}
