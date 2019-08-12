//
//  SelectableSegmentInteractor+Filter+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension SelectableSegmentInteractor where Segment: FilterType {
  
  func connectController<Controller: SelectableSegmentController>(_ controller: Controller,
                                                                  presenter: @escaping FilterPresenter = DefaultPresenter.Filter.present) where Controller.SegmentKey == SegmentKey {
    
    func setControllerItems(controller: Controller, with items: [SegmentKey: Segment]) {
      let itemsToPresent = items
        .map { ($0.key, presenter(Filter($0.value))) }
        .reduce(into: [:]) { $0[$1.0] = $1.1 }
      controller.setItems(items: itemsToPresent)
    }
    
    controller.setSelected(selected)
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller) { controller, selectedItem in
      controller.setSelected(selectedItem)
    }
    onItemsChanged.subscribePast(with: controller, callback: setControllerItems)
    
  }
  
}
