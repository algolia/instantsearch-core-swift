//
//  SelectableMapViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 10/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SelectableMapViewModel<Key: Hashable, Value> {
  
  public var items: [Key: Value]
  public var selected: Key?
  public let onSelectedChanged: Observer<Key?>
  public let onSelectedComputed: Observer<Key?>
  
  public init(items: [Key: Value], selected: Key? = nil) {
    self.items = items
    self.selected = selected
    self.onSelectedChanged = Observer()
    self.onSelectedComputed = Observer()
  }
  
  public func computeSelected(selected: Key) {
    onSelectedComputed.fire(selected)
  }
  
}
