//
//  FacetListInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum FacetList {
  
  public struct FilterStateConnection: Connection {
    
    public let facetListInteractor: FacetListInteractor
    public let filterState: FilterState
    public let attribute: Attribute
    public let `operator`: RefinementOperator
    public let groupName: String?
    
    public func connect() {
      let groupName = self.groupName ?? attribute.name
      
      switch `operator` {
      case .and:
        facetListInteractor.connectFilterState(filterState, with: attribute, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
        
      case .or:
        facetListInteractor.connectFilterState(filterState, with: attribute, via: filterState[or: groupName])
      }
    }
    
    public func disconnect() {
      facetListInteractor.onSelectionsComputed.cancelSubscription(for: filterState)
      filterState.onChange.cancelSubscription(for: facetListInteractor)
    }
    
  }

}

public extension FacetListInteractor {
  
  @discardableResult func connectFilterState(_ filterState: FilterState,
                                             with attribute: Attribute,
                                             operator: RefinementOperator,
                                             groupName: String? = nil) -> FacetList.FilterStateConnection {
    let connection = FacetList.FilterStateConnection(facetListInteractor: self, filterState: filterState, attribute: attribute, operator: `operator`, groupName: groupName)
    connection.connect()
    return connection
  }
  
}

private extension FacetListInteractor {
  
  func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, with attribute: Attribute, via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    whenSelectionsComputedThenUpdateFilterState(filterState, attribute: attribute, via: accessor)
    whenFilterStateChangedThenUpdateSelections(filterState: filterState, via: accessor)
  }
  
  func whenSelectionsComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                       attribute: Attribute,
                                                                                       via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    onSelectionsComputed.subscribePast(with: filterState) { filterState, selections in
      let filters = selections.map { Filter.Facet(attribute: attribute, stringValue: $0) }
      accessor.removeAll()
      accessor.addAll(filters)
      filterState.notifyChange()
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections<Accessor: SpecializedGroupAccessor>(filterState: FilterState, via accessor: Accessor) where Accessor.Filter == Filter.Facet {
    
    func extractString(from filter: Filter.Facet) -> String? {
      if case .string(let stringValue) = filter.value {
        return stringValue
      } else {
        return nil
      }
    }
    
    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.selections = Set(accessor.filters().compactMap(extractString))
    }
  }
    
}
