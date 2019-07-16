//
//  HierarchicalViewModel+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 08/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalViewModel {

  func connectController<O, C>(_ controller: C, presenter: @escaping ([HierarchicalFacet]) -> O) where O == C.Item, C: HierarchicalController {
    onItemChanged.subscribePast(with: self) { facets in

      let hierarchicalFacets = facets.enumerated()
        .map { index, items in
          items.map { item in
            (item, index, self.selections.contains(item.value))
          }
        }.flatMap { $0 }

      controller.setItem(presenter(hierarchicalFacets)) 
    }

    controller.onClick = computeSelection(key:)
  }

}

public extension HierarchicalViewModel {
  func connectController<C>(_ controller: C, presenter: @escaping HierarchicalPresenter = DefaultPresenter.Hierarchical.present) where C: HierarchicalController, C.Item == [HierarchicalFacet] {
    onItemChanged.subscribePast(with: self) { facets in

      let hierarchicalFacets = facets.enumerated()
        .map { index, items in
          items.map { item in
            (item, index, self.selections.contains(item.value))
          }
        }.flatMap { $0 }
      
      controller.setItem(presenter(hierarchicalFacets))
    }

    controller.onClick = computeSelection(key:)
  }
}

public typealias HierarchicalFacet = (facet: Facet, level: Int, isSelected: Bool)
