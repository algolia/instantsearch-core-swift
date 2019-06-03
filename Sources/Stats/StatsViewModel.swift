//
//  StatsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class StatsViewModel: ItemViewModel<SearchStats?> {}

public extension StatsViewModel {
  
  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>) {
    searcher.onResultsChanged.subscribe(with: self) { arg in
      let (_, _, result) = arg
      if case .success(let searchResults) = result {
        self.item = searchResults.stats
      } else {
        self.item = .none
      }
    }
  }
  
  func connectController<C: ItemController>(_ controller: C) where C.Item == SearchStats? {
    onItemChanged.subscribe(with: controller) { searchResults in
      controller.setItem(searchResults)
    }
  }
  
}
