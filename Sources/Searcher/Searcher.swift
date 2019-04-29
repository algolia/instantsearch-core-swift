//
//  Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol Searcher: SequencerDelegate {
  
  var sequencer: Sequencer { get }
  var isLoading: Observer<Bool> { get }
  
  func search()
  func cancel()
  func setQuery(text: String)
  
}

// Sequencer Delegate

extension Searcher {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
    isLoading.fire(hasPendingOperations)
  }
}

extension Searcher {
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
  func transform<T: Decodable>(content: [String: Any]?, error: Error?) -> Result<T, Error> {
    let result = Result(value: content, error: error)
    
    switch result {
    case .success(let value):
      do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        let decoder = JSONDecoder()
        
        let result = try decoder.decode(T.self, from: data)
        return .success(result)
      } catch let error {
        return .failure(error)
      }
      
    case .failure(let error):
      return .failure(error)
    }
    
  }
  
}

public protocol SearchResultObservable {
  
  associatedtype SearchResult
  
  var onResultsChanged: Observer<SearchResult> { get }
  
}
