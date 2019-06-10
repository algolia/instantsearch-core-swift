//
//  StatsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class StatsViewModel: ItemViewModel<SearchStats?> {}

public typealias StatsPresenter<Output> = (SearchStats?) -> Output

public struct DefaultStatsPresenter {
  
  public static let present: StatsPresenter<String?> = { stats in
    return (stats?.totalHitsCount).flatMap { "hits: \($0)" }
  }
  
}

public extension StatsViewModel {
  
  func connectSearcher(_ searcher: SingleIndexSearcher) {
    
    searcher.onResults.subscribePast(with: self) { [weak self] searchResults in
        self?.item = searchResults.stats
    }
    
    searcher.onError.subscribe(with: self) { [weak self] _ in
      self?.item = .none
    }
    
  }
  
  func connectController<C: ItemController, Output>(_ controller: C, presenter: @escaping StatsPresenter<Output>) where C.Item == Output {
    onItemChanged.subscribePast(with: controller) { itemToPresent in
      let presentableItem = presenter(itemToPresent)
      controller.setItem(presentableItem)
    }
  }
  
}
