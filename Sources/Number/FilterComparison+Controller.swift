//
//  FilterComparisonConnectView.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension NumberInteractor {
  
  public func connectController<Controller: NumberController>(_ controller: Controller) where Controller.Item == Number {

    let computation = Computation(numeric: item) { [weak self] numeric in
      self?.computeNumber(number: numeric)
    }

    controller.setComputation(computation: computation)

    onItemChanged.subscribePast(with: controller) { controller, item in
      guard let item = item else {
        controller.invalidate()
        return
      }
      controller.setItem(item)
    }
  }
  
}
