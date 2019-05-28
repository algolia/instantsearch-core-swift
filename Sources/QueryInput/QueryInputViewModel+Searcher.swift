//
//  QueryInputViewModel+Searcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension QueryInputViewModel {

  public func connect<S: Searcher>(to searcher: S, searchAsYouType: Bool) {
    query = searcher.query
    
    if searchAsYouType {
      onQueryChanged.subscribe(with: self) { query in
        searcher.query = query
        searcher.search()
      }
    } else {
      onQuerySubmitted.subscribe(with: self) { query in
        searcher.query = query
        searcher.search()
      }
    }
  }
  
}
