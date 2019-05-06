//
//  SelectableViewModel.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 03/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SelectableViewModel<Item> {
  
  public let item: Item
  public var isSelected: Bool {
    didSet {
      onSelectedChanged.fire(isSelected)
    }
  }
  public var onSelectedChanged: Observer<Bool>
  public var onSelectedComputed: Observer<Bool>

  public init(item: Item) {
    self.item = item
    self.isSelected = false
    self.onSelectedChanged = Observer()
    self.onSelectedComputed = Observer()
  }
  
  public func computeIsSelected(selecting: Bool) {
    onSelectedComputed.fire(selecting)
  }
  
}
