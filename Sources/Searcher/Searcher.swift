//
//  Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol Searcher: class {
  
  var query: String? { get set }
    
  var isLoading: Observer<Bool> { get }
  var onQueryChanged: Observer<String?> { get }
  
  func search()
  func cancel()
  
}

extension Searcher {
    
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

extension Searcher where Self: SequencerDelegate {
  public func didChangeOperationsState(hasPendingOperations: Bool) {
    isLoading.fire(hasPendingOperations)
  }
}

public protocol SearchResultObservable {
  
  associatedtype SearchResult
  
  var onResults: Observer<SearchResult> { get }
  
}

