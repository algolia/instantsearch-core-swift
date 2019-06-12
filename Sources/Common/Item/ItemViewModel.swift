//
//  ItemViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 31/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class ItemViewModel<Item> {
  
  public var item: Item {
    didSet {
      onItemChanged.fire(item)
    }
  }
  
  let onItemChanged: Observer<Item>
  
  init(item: Item) {
    self.item = item
    self.onItemChanged = Observer()
  }
  
}

public extension ItemViewModel {
  func connectController<O, C: ItemController>(_ controller: C, dispatchOnMainThread: Bool = false, presenter: @escaping Presenter<Item, O>) where C.Item == O {
    let sub = onItemChanged.subscribePast(with: controller) { (item) in
      controller.setItem(presenter(item))
    }

    if dispatchOnMainThread {
      sub.onQueue(.main)
    }
  }
}
