//
//  MultiHitsController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol MultiHitsController: class {
  
  var hitsSource: MultiHitsSource? { get set }
  
  func reload()
  
  func scrollToTop()
  
}

extension MultiHitsViewModel: MultiHitsSource {}

public extension MultiHitsViewModel {
  
  func connectController<Controller: MultiHitsController>(_ controller: Controller) {
    
    controller.hitsSource = self
    
    onRequestChanged.subscribe(with: controller) { _ in
      controller.scrollToTop()
    }.onQueue(.main)
    
    onResultsUpdated.subscribePast(with: controller) { _ in
      controller.reload()
    }.onQueue(.main)
  }
  
}
