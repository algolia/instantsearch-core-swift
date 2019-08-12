//
//  NumberRangeInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension NumberRangeInteractor {
  public func connectController<Controller: NumberRangeController>(_ controller: Controller) where Controller.Number == Number {

    onItemChanged.subscribePast(with: self) { _, item in
      guard let item = item else {
        controller.invalidate()
        return
      }
      controller.setItem(item)
    }

    controller.onRangeChanged = { [weak self] closedRange in
      self?.computeNumberRange(numberRange: closedRange)
    }

    onBoundsComputed.subscribePast(with: controller) { controller, bounds in
      bounds.flatMap(controller.setBounds)
    }
    
  }
}
