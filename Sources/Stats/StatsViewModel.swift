//
//  StatsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class StatsViewModel: ItemViewModel<SearchStats?> {
  public init() {
    super.init(item: .none)
  }
}

public typealias StatsPresenter<Output> = Presenter<SearchStats?, Output>

public struct DefaultStatsPresenter {
  
  public static let present: StatsPresenter<String?> = { stats in
    return (stats?.totalHitsCount).flatMap { "\($0) results" }
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

  func connectController<C: StatsTextController>(_ controller: C, presenter: Presenter<SearchStats?, String?>? = nil) {
    let statsPresenter = presenter ?? DefaultStatsPresenter.present
    connectController(controller, presenter: statsPresenter)
  }
}
