//
//  HierarchicalViewModel+Controller.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 08/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HierarchicalViewModel {

  func connectController<O, C>(_ controller: C, presenter: @escaping ([HierarchicalFacet]) -> O) where O == C.Item, C : HierarchicalController {
    onItemChanged.subscribePast(with: self) { facets in

      let hierarchicalFacets = facets.enumerated()
        .map { index, items in
          items.map {
            item in (item, index, self.selections.contains(item.value))
          }
        }.flatMap { $0 }

      controller.setItem(presenter(hierarchicalFacets)) 
    }

    controller.onClick = computeSelection(key:)
  }

}

public typealias HierarchicalFacet = (facet: Facet, level: Int, isSelected: Bool)

public typealias HierarchicalPresenter = ([HierarchicalFacet]) -> [HierarchicalFacet]

public struct DefaultHierarchicalPresenter {

  public static let present: HierarchicalPresenter = { facets in
    let levels = Set(facets.map { $0.level }).sorted()

    var output: [HierarchicalFacet] = facets.filter { $0.level == 0 }

    for i in 1..<levels.count {
      let hierarchicalFacetsAtSpecificLevel = facets.filter { $0.level == i }
      if let indexOfSelectedOneLevelBelow = output.lastIndex(where: { $0.level == i-1 && $0.isSelected }) {
        output.insert(contentsOf: hierarchicalFacetsAtSpecificLevel, at: indexOfSelectedOneLevelBelow + 1)
      }
    }

    return output
  }

}
