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

extension HitsViewModel: HitsSource {}

public extension HitsViewModel {
  
  func connectController<Controller: HitsController>(_ controller: Controller) where Controller.DataSource == HitsViewModel<Record> {
    controller.hitsSource = self
    onResultsUpdated.subscribe(with: controller) { _ in
      controller.reload()
    }
  }
  
}
