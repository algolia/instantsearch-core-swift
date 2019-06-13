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

  // TODO: Potentially we could change from Item to a Int which is position of item in list.
  // It is enough to identify the items in viewModel, so in that way we only pass the
  // Filter without the ID
  var onRemoveItem: ((Item) -> Void)? { get set }

  func reload()
}
