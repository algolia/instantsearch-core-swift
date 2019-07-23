//
//  MultiIndexHitsController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol MultiIndexHitsController: class {
  
  var hitsSource: MultiIndexHitsSource? { get set }
  
  func reload()
  
  func scrollToTop()
  
}

extension MultiIndexHitsInteractor: MultiIndexHitsSource {}

<<<<<<< HEAD
=======
public extension MultiIndexHitsViewModel {
  
  func connectController<Controller: MultiIndexHitsController>(_ controller: Controller) {
    
    controller.hitsSource = self
    
    onRequestChanged.subscribe(with: controller) { controller, _ in
      controller.scrollToTop()
    }.onQueue(.main)
    
    onResultsUpdated.subscribePast(with: controller) { controller, _ in
      controller.reload()
    }.onQueue(.main)
    
    controller.reload()
  }
  
}
>>>>>>> Adding strongly typed observer to signal
