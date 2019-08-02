//
//  FacetListInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FacetListInteractor {
  
  func connectController<C: FacetListController>(_ controller: C, with presenter: SelectableListPresentable? = nil) {
    
    /// Add missing refinements with a count of 0 to all returned facets
    /// Example: if in result we have color: [(red, 10), (green, 5)] and that in the refinements
    /// we have "color: red" and "color: yellow", the final output would be [(red, 10), (green, 5), (yellow, 0)]
    func merge(_ facets: [Facet], withSelectedValues selections: Set<String>) -> [SelectableItem<Facet>] {
      return facets.map { SelectableItem<Facet>($0, selections.contains($0.value)) }
    }
    
    func setControllerItemsWith(facets: [Facet], selections: Set<String>) {
      let updatedFacets = merge(facets, withSelectedValues: selections)
      let sortedFacetValues = presenter?.transform(refinementFacets: updatedFacets) ?? updatedFacets
      controller.setSelectableItems(selectableItems: sortedFacetValues)
      controller.reload()
    }
    
    setControllerItemsWith(facets: items, selections: selections)
    
    controller.onClick = { [weak self] facet in
      self?.computeSelections(selectingItemForKey: facet.value)
    }
    
    onItemsChanged.subscribePast(with: self) { interactor, facets in
      setControllerItemsWith(facets: facets, selections: interactor.selections)
    }
    
    onSelectionsChanged.subscribePast(with: self) { interactor, selections in
      setControllerItemsWith(facets: interactor.items, selections: selections)
    }
    
  }
  
}
