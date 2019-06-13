//
//  CurrentFiltersController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol ItemListController: class {

  associatedtype Item: Hashable

  func setItems(_ item: Set<Item>)

  var onRemoveItem: ((Item) -> Void)? { get set }

  func reload()
}
