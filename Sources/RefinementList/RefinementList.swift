//
//  RefinementList.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 26/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public protocol SelectableListView {
  associatedtype Item

  func setSelectableItems(selectableItems: [SelectableItem<Item>])

  func onClickItem(onClick: (Item) -> Void)

  func reload()

}

public protocol RefinementFacetsView: SelectableListView where Item == RefinementFacet {}
