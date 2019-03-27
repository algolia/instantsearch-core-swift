//
//  Searchers.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
//
//  Searchers.swift
//  InstantSearch
//
//  Created by Guy Daher on 25/02/2019.
//

import Foundation
import InstantSearchClient
import Signals

public protocol Searcher: SequencerDelegate {
  func search()
  func cancel()
  func setQuery(text: String)
  var sequencer: Sequencer { get }
  var isLoading: Signal<Bool> { get }
}

extension Searcher {

  public func cancel() {
    sequencer.cancelPendingOperations()
  }

  func transform<T: Decodable>(content: [String: Any]?, error: Error?) -> Result<T> {
    let result = Result(value: content, error: error)

    switch result {
    case .success(let value):
      do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        let decoder = JSONDecoder()

        let result = try decoder.decode(T.self, from: data)
        return Result(value: result)
      } catch let error {
        return Result(error: error)
      }
    case .fail(let error):
      return Result(error: error)
    }

  }

}

// Sequencer Delegate

extension Searcher {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
//    print("Has pending operations: \(hasPendingOperations)")
    isLoading.fire(hasPendingOperations)
  }
}

// TODO: don t forget to add RequestOption everywhere

public class SingleIndexSearcher<Record: Codable>: Searcher {

  public let sequencer: Sequencer
  public let isLoading = Signal<Bool>()

  public var index: Index
  public let query: Query
  public let filterBuilder: FilterBuilder

  // TODO: Refactor with typealiases, same for other searchers
  public let onSearchResults = Signal<(QueryMetadata, Result<SearchResults<Record>>)>()

  public var applyDisjunctiveFacetingWhenNecessary = true

  public init(index: Index, query: Query, filterBuilder: FilterBuilder) {
    self.index = index
    self.query = query
    self.filterBuilder = filterBuilder
    sequencer = Sequencer()
    sequencer.delegate = self
    onSearchResults.retainLastData = true
    isLoading.retainLastData = true
  }

  public func setQuery(text: String) {
    self.query.query = text
  }

  fileprivate func handle(_ value: [String: Any]?, _ error: Error?, _ queryMetadata: QueryMetadata) {
    let result: Result<SearchResults<Record>> = self.transform(content: value, error: error)
    self.onSearchResults.fire((queryMetadata, result))
  }

  public func search() {
    // TODO: weak self...
    sequencer.orderOperation {
      let queryMetadata = QueryMetadata(query: self.query)

      if applyDisjunctiveFacetingWhenNecessary && filterBuilder.isDisjunctiveFacetingAvailable() {
        let disjunctiveFacets = Array(filterBuilder.getDisjunctiveFacetsAttributes()).map { $0.description }
        let refinements = filterBuilder.getRawFacetFilters()

        return self.index.searchDisjunctiveFaceting(query, disjunctiveFacets: disjunctiveFacets, refinements: refinements) { value, error in
          self.handle(value, error, queryMetadata)
        }
      } else {
        query.filters = filterBuilder.build()
        return self.index.search(query) { value, error in
          self.handle(value, error, queryMetadata)
        }
      }
    }
  }

  public func cancel() {
    sequencer.cancelPendingOperations()
  }
}

public class MultiIndexSearcher: Searcher {

  public let indexQueries: [IndexQuery]
  public let filterBuilders: [FilterBuilder]
  let client: Client
  public let sequencer: Sequencer
  public let isLoading = Signal<Bool>()

  public var onSearchResults = Signal<Result<[(QueryMetadata, SearchResults<JSON>)]>>()

  public var applyDisjunctiveFacetingWhenNecessary = true

  public convenience init(client: Client, indices: [Index], queries: [Query], filterBuilders: [FilterBuilder]) {
    self.init(client: client, indexQueries: zip(indices, queries).map { IndexQuery(index: $0, query: $1) }, filterBuilders: filterBuilders )
  }

  public convenience init(client: Client, indices: [Index], query: Query, filterBuilder: FilterBuilder) {
    self.init(client: client, indexQueries: indices.map { IndexQuery(index: $0, query: query) }, filterBuilders: [filterBuilder])
  }

  public init(client: Client, indexQueries: [IndexQuery], filterBuilders: [FilterBuilder]) {
    self.indexQueries = indexQueries
    self.filterBuilders = filterBuilders
    self.client = client
    self.sequencer = Sequencer()
    sequencer.delegate = self
    onSearchResults.retainLastData = true
    isLoading.retainLastData = true
  }

  public func setQuery(text: String) {
    self.indexQueries.forEach { $0.query.query = text }
  }

  public func search() {
    zip(indexQueries, filterBuilders).forEach { (indexQuery, filterBuilder) in
      indexQuery.query.filters = filterBuilder.build()
    }

    sequencer.orderOperation {
      return self.client.multipleQueries(indexQueries) { (content, error) in
        
        let result: Result<MultiSearchResults<JSON>> = self.transform(content: content, error: error)
        
        let output: Result<[(QueryMetadata, SearchResults<JSON>)]>
        
        switch result {
        case .success(let searchResultsWrapper):
          let queryMetadata = self.indexQueries.map { $0.query }.map(QueryMetadata.init(query:))
          let searchResults = searchResultsWrapper.searchResults
          let searchResultsWithMetadata = zip(queryMetadata, searchResults).map { ($0, $1) }
          output = .success(searchResultsWithMetadata)
          
        case .fail(let error):
          output = .fail(error)
        }
        
        self.onSearchResults.fire(output)
        
      }
    }
  }

  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}

public class SearchForFacetValueSearcher: Searcher {

  public let index: Index
  public let query: Query
  public let filterBuilder: FilterBuilder
  public var facetName: String
  public var text: String
  public let sequencer: Sequencer
  public let onSearchResults = Signal<Result<FacetResults>>()
  public let isLoading = Signal<Bool>()

  public init(index: Index, query: Query, filterBuilder: FilterBuilder, facetName: String, text: String) {
    self.index = index
    self.query = query
    self.facetName = facetName
    self.filterBuilder = filterBuilder
    self.text = text
    self.sequencer = Sequencer()
    sequencer.delegate = self
    onSearchResults.retainLastData = true
    isLoading.retainLastData = true
  }

  public func setQuery(text: String) {
    self.text = text
  }

  public func search() {
    query.filters = filterBuilder.build()
    
    sequencer.orderOperation {
      return self.index.searchForFacetValues(of: facetName, matching: text) { (content, error) in
        let result: Result<FacetResults> = self.transform(content: content, error: error)
        self.onSearchResults.fire(result)
      }
    }
  }

}
