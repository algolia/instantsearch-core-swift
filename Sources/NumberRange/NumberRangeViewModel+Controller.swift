//
//  NumberRangeViewModel+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension NumberRangeViewModel {
  public func connectView<View: NumberRangeController>(view: View) where View.Number == Number {

    onItemChanged.subscribePast(with: self) { (item) in
      guard let item = item else {
        view.invalidate()
        return
      }
      view.setItem(item)
    }

    view.onRangeChanged = { [weak self] closedRange in
      self?.computeNumberRange(numberRange: closedRange)
    }

    onBoundsComputed.subscribePast(with: view) { (bounds) in
      guard let bounds = bounds else { return }
      view.setBounds(bounds)
    }
    
  }
}
