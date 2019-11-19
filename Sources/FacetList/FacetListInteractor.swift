//
//  RefinementFacetInteractor.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias FacetListInteractor = SelectableListInteractor<String, Facet>

public extension FacetListInteractor {
  
  convenience init(selectionMode: SelectionMode = .multiple) {
    self.init(items: [], selectionMode: selectionMode)
  }
  
}

public enum FacetSortCriterion {
  
  case count(order: Order)
  case alphabetical(order: Order)
  case isRefined

  public enum Order {
    case ascending
    case descending
  }
}

public enum RefinementOperator {
  // when operator is 'and' + one single value can be selected,
  // we want to keep the other values visible, so we have to do a disjunctive facet
  // In the case of multi value that can be selected in conjunctive case,
  // then we avoid doing a disjunctive facet and just do normal conjusctive facet
  // and only the remaining possible facets will appear.
  case and
  case or

}
