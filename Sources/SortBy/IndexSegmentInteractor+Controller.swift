//
//  IndexSegmentInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 06/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension IndexSegmentInteractor {
  
  func connectController<Controller: SelectableSegmentController>(_ controller: Controller,
                                                                  presenter: @escaping IndexPresenter = DefaultPresenter.Index.present) where Controller.SegmentKey == SegmentKey {

    controller.setItems(items: items.mapValues(presenter))
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller) { controller, selectedItem in
      controller.setSelected(selectedItem)
    }
    onItemsChanged.subscribePast(with: controller) { controller, newItems in
      controller.setItems(items: newItems.mapValues(presenter))
    }

  }
  
}
