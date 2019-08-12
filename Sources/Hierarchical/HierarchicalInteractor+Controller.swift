//
//  HierarchicalInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 08/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalInteractor {

  func connectController<Controller: HierarchicalController, Output>(_ controller: Controller,
                                                                     presenter: @escaping ([HierarchicalFacet]) -> Output) where Output == Controller.Item {
    onItemChanged.subscribePast(with: self) { interactor, facets in

      let hierarchicalFacets = facets.enumerated()
        .map { index, items in
          items.map { item in
            (item, index, interactor.selections.contains(item.value))
          }
        }.flatMap { $0 }

      controller.setItem(presenter(hierarchicalFacets)) 
    }

    controller.onClick = computeSelection(key:)
  }

}

public extension HierarchicalInteractor {
  
  func connectController<Controller: HierarchicalController>(_ controller: Controller,
                                                             presenter: @escaping HierarchicalPresenter = DefaultPresenter.Hierarchical.present) where Controller.Item == [HierarchicalFacet] {
    onItemChanged.subscribePast(with: self) { interactor, facets in

      let hierarchicalFacets = facets.enumerated()
        .map { index, items in
          items.map { item in
            (item, index, interactor.selections.contains(item.value))
          }
        }.flatMap { $0 }
      
      controller.setItem(presenter(hierarchicalFacets))
    }

    controller.onClick = computeSelection(key:)
  }
  
}

public typealias HierarchicalFacet = (facet: Facet, level: Int, isSelected: Bool)
