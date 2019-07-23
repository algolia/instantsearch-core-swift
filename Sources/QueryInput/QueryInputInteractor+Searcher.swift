//
//  QueryInputInteractor+Searcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum SearchTriggeringMode {
  case searchAsYouType
  case searchOnSubmit
}

extension QueryInputInteractor {

  public func connectSearcher<S: Searcher>(_ searcher: S, searchTriggeringMode: SearchTriggeringMode = .searchAsYouType) {
    
    query = searcher.query
    
    switch searchTriggeringMode {
    case .searchAsYouType:
      onQueryChanged.subscribe(with: searcher) { searcher, query in
        searcher.query = query
        searcher.search()
      }
      
    case .searchOnSubmit:
      onQuerySubmitted.subscribe(with: searcher) { searcher, query in
        searcher.query = query
        searcher.search()
      }
    }

  }
  
}
