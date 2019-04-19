//
//  SelectionListPresenter.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 18/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol SelectionListPresenter {

  associatedtype Item: Equatable
  
  typealias SelectableItemComparator = (SelectableItem<Item>, SelectableItem<Item>) -> Bool

  var comparator: SelectableItemComparator { get }

  var limit: Int { get }

  var values: [SelectableItem<Item>] { get }

  var onValuesChanged: Observer<[SelectableItem<Item>]> { get }

  func recomputeValues()
  
}
