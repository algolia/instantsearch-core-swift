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
  public let onSearchResults = Observer<SearchResult>()
  public let isLoading = Observer<Bool>()
  public var facetName: String
  public var text: String
  
  public init(index: Index, query: Query, filterBuilder: FilterBuilder, facetName: String, text: String) {
    self.indexSearchData = IndexSearchData(index: index, query: query, filterBuilder: filterBuilder)
    self.facetName = facetName
    self.text = text
    self.sequencer = Sequencer()
    sequencer.delegate = self
    onSearchResults.retainLastData = true
    isLoading.retainLastData = true
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
        self.onSearchResults.fire((metadata, result))
      }
    }
    
  }
  
}
