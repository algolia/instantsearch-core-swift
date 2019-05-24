//
//  Searcher+SerchableController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 22/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension Searcher {
  func connectController(_ searchableController: SearchableController) {
    searchableController.onSearch.subscribePast(with: self) { [weak self] text in
      self?.setQuery(text: text)
      self?.search()
    }
  }
}
