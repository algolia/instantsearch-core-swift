//
//  SerchableController+Searcher.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 22/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SearchableController {

  func connectTo(_ searcher: Searcher) {
    onSearch.subscribePast(with: searcher) { [weak searcher] text in
      searcher?.setQuery(text: text)
      searcher?.search()
    }
  }
}
