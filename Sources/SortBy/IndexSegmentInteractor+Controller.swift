//
//  IndexSegmentInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 06/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension IndexSegmentInteractor {
  func connectController<C: SelectableSegmentController>(_ controller: C, presenter: IndexPresenter? = .none) where C.SegmentKey == SegmentKey {

    let presenter = presenter ?? DefaultPresenter.Index.present

    controller.setItems(items: items.mapValues { presenter($0) })
    controller.onClick = computeSelected(selecting:)
    onSelectedChanged.subscribePast(with: controller) { controller, selectedItem in
      controller.setSelected(selectedItem)
    }
    onItemsChanged.subscribePast(with: controller) { controller, newItems in
      controller.setItems(items: newItems.mapValues { presenter($0) })
    }

  }
}
