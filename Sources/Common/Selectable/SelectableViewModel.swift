//
//  SelectableViewModel.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 03/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SelectableViewModel<Item> {
  
  public var item: Item {
    didSet {
      onItemChanged.fire(item)
    }
  }
  
  public var isSelected: Bool {
    didSet {
      onSelectedChanged.fire(isSelected)
    }
  }
  
  public let onItemChanged: Observer<Item>
  public let onSelectedChanged: Observer<Bool>
  public let onSelectedComputed: Observer<Bool>

  public init(item: Item) {
    self.item = item
    self.isSelected = false
    self.onItemChanged = Observer()
    self.onSelectedChanged = Observer()
    self.onSelectedComputed = Observer()
  }
  
  public func computeIsSelected(selecting: Bool) {
    onSelectedComputed.fire(selecting)
  }
  
}
