//
//  StatsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class StatsViewModel<Record: Codable>: ItemViewModel<SearchResults<Record>> {}

extension StatsViewModel {
  
  func connectSearcher(_ searcher: SingleIndexSearcher<Record>) {
    searcher.onResultsChanged.subscribe(with: self) { arg in
      let (_, _, result) = arg
      if case .success(let searchResults) = result {
        self.item = searchResults
      }
    }
  }
  
  func connectController<C: StatsController>(_ controller: C) where C.Record == Record {
    onItemChanged.subscribe(with: controller) { searchResults in
      controller.setItem(searchResults)
    }
  }
  
}
