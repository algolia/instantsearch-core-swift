//
//  FilterListInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableListInteractor where Key == Item, Item: FilterType {

  func connectController<Controller: SelectableListController>(_ controller: Controller) where Controller.Item == Item {
    
    func setControllerItemsWith(items: [Item], selections: Set<Key>) {
      let selectableItems = items.map { ($0, selections.contains($0)) }
      controller.setSelectableItems(selectableItems: selectableItems)
      controller.reload()
    }
    
    setControllerItemsWith(items: items, selections: selections)
    
    controller.onClick = computeSelections(selectingItemForKey:)
    
    onItemsChanged.subscribePast(with: self) { interactor, items in
      setControllerItemsWith(items: items, selections: interactor.selections)
    }
    
    onSelectionsChanged.subscribePast(with: self) { interactor, selections in
      setControllerItemsWith(items: interactor.items, selections: selections)
    }
    
  }
  
}
