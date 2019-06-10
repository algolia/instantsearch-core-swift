//
//  NumberViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 04/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class NumberViewModel<Number: Comparable & Numeric & InitaliazableWithFloat>: ItemViewModel<Number?> {

  public let onNumberComputed: Observer<Number?>
  public let onBoundsComputed: Observer<ClosedRange<Number>?>

  public private(set) var bounds: ClosedRange<Number>?

  public convenience init() {
    self.init(item: nil)
  }

  public override init(item: Number?) {
    self.onNumberComputed = Observer()
    self.onBoundsComputed = Observer()
    super.init(item: item)
  }

  public func applyBounds(bounds: ClosedRange<Number>?) {
    let coerced = item?.coerce(in: bounds)
    self.bounds = bounds

    onBoundsComputed.fire(bounds)
    onNumberComputed.fire(coerced)
  }

  public func computeNumber(number: Number?) {
    let coerced = number?.coerce(in: bounds)

    onNumberComputed.fire(coerced)
  }
}

extension Comparable {
  func coerce(in range: ClosedRange<Self>?) -> Self {
    guard let range = range else { return self }
    if self < range.lowerBound { return range.lowerBound }
    if self > range.upperBound { return range.upperBound }
    return self
  }
}