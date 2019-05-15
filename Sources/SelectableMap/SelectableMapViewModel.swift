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
  public var selected: Key? {
    didSet {
      onSelectedChanged.fire(selected)
    }
  }
  public let onSelectedChanged: Observer<Key?>
  public let onSelectedComputed: Observer<Key?>
  
  public init(items: [Key: Value]) {
    self.items = items
    self.onSelectedChanged = Observer()
    self.onSelectedComputed = Observer()
  }
  
  public func computeSelected(selected: Key) {
    onSelectedComputed.fire(selected)
  }
  
}
