//
//  FilterComparisonConnectView.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension NumberViewModel {
  public func connectView<View: NumberController>(view: View) where View.Item == Number {

    let computation = Computation(numeric: item) { [weak self] numeric in
      self?.computeNumber(number: numeric)
    }

    view.setComputation(computation: computation)

    onItemChanged.subscribePast(with: self) { (item) in
      guard let item = item else { return }
      view.setItem(item)
    }
  }
}
