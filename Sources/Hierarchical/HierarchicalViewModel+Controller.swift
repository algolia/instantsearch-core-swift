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
    
    guard !levels.isEmpty else { return facets }
    
    var output: [HierarchicalFacet] = []
    
    output.reserveCapacity(facets.count)
    levels.forEach { level in
        let facetsForLevel = facets
            .filter { $0.level == level }
            .sorted { $0.facet.value < $1.facet.value }
        let indexToInsert = output
            .lastIndex { $0.isSelected }
            .flatMap { output.index(after: $0) } ?? output.endIndex
        output.insert(contentsOf: facetsForLevel, at: indexToInsert)
    }

    return output
  }

}
