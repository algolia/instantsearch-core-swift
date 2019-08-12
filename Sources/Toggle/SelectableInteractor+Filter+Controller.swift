//
//  SelectableInteractor+Filter+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableInteractor where Item: FilterType {
  
  func connectController<C: SelectableController>(_ controller: C) where C.Item == Item {
    controller.setItem(item)
    controller.setSelected(isSelected)
    controller.onClick = computeIsSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller) { controller, isSelected in
      controller.setSelected(isSelected)
    }
    onItemChanged.subscribePast(with: controller) { controller, item in
      controller.setItem(item)
    }
  }
  
}
