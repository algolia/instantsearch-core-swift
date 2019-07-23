//
//  HitsController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol HitsController: class {
  
  associatedtype DataSource: HitsSource
  
  var hitsSource: DataSource? { get set }
  
  func reload()
  
  func scrollToTop()
  
}

extension HitsInteractor: HitsSource {}

public extension HitsInteractor {
  
  func connectController<Controller: HitsController>(_ controller: Controller) where Controller.DataSource == HitsInteractor<Record> {
    
    controller.hitsSource = self
    
    onRequestChanged.subscribe(with: self) { _ in
      controller.scrollToTop()
    }.onQueue(.main)
    
    onResultsUpdated.subscribePast(with: controller) { searchResults in
      do {
        let hits = try searchResults.deserializeHits() as [Movie]
        print(hits.map { $0.title })
      } catch _ {
        
      }

      controller.reload()
    }.onQueue(.main)
  }
  
}

struct Movie: Codable {
  let title: String
  let year: Int
  let image: URL
  let genre: [String]
}
