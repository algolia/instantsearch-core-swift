//
//  MultiIndexSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class MultiIndexSearcher: Searcher, SearchResultObservable {
  
  public typealias SearchResult = Result<[(QueryMetadata, SearchResults<JSON>)], Error>
  
  public let client: Client
  public var indexSearchDatas: [IndexSearchData]
  public let sequencer: Sequencer
  public let isLoading = Observer<Bool>()
  public let onResultsChanged = Observer<SearchResult>()
  public var applyDisjunctiveFacetingWhenNecessary = true
  
  public convenience init(client: Client, indices: [Index], query: Query, filterState: FilterState, requestOptions: RequestOptions? = nil) {
    self.init(client: client, indexSearchDatas: [IndexSearchData](indices: indices, query: query, filterState: filterState, requestOptions: requestOptions))
  }
  
  public init(client: Client, indexSearchDatas: [IndexSearchData]) {
    self.client = client
    self.indexSearchDatas = indexSearchDatas
    self.sequencer = Sequencer()
    sequencer.delegate = self
    onResultsChanged.retainLastData = true
    isLoading.retainLastData = true

//    filterState.onChange.subscribe(with: self) { _ in
//      self.search()
//    }
  }
  
  public func setQuery(text: String) {
    indexSearchDatas.forEach { $0.query.query = text }
  }
  
  public func search() {
    
    indexSearchDatas.forEach { $0.applyFilters() }
    
    let indexQueries = indexSearchDatas.map(IndexQuery.init(indexSearchData:))
    let metadata = self.indexSearchDatas.map { $0.query }.map(QueryMetadata.init(query:))
    
    sequencer.orderOperation {
      // TODO: Make sure can only have 1 request Option in the class, else we need to change that. 
      return self.client.multipleQueries(indexQueries, requestOptions: indexSearchDatas.first?.requestOptions) { (content, error) in
        
        let result: Result<MultiSearchResults<JSON>, Error> = self.transform(content: content, error: error)
        
        let output: Result<[(QueryMetadata, SearchResults<JSON>)], Error>
        
        switch result {
        case .success(let searchResultsWrapper):
          let searchResults = searchResultsWrapper.searchResults
          let searchResultsWithMetadata = zip(metadata, searchResults).map { ($0, $1) }
          output = .success(searchResultsWithMetadata)
          
        case .failure(let error):
          output = .failure(error)
        }
        
        self.onResultsChanged.fire(output)
        
      }
    }
  }
  
}
