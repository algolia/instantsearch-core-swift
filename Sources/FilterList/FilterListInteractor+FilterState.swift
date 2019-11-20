//
//  FilterListInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public enum FilterList {
  
  public struct FilterStateConnection<Filter: FilterType & Hashable>: Connection {

    public let interactor: SelectableListInteractor<Filter, Filter>
    public let filterState: FilterState
    public let `operator`: RefinementOperator
    public let groupName: String
    
    public init(interactor: SelectableListInteractor<Filter, Filter>,
                filterState: FilterState,
                `operator`: RefinementOperator,
                groupName: String = "") {
      self.interactor = interactor
      self.filterState = filterState
      self.operator = `operator`
      self.groupName = groupName
    }
    
    public func connect() {
      switch `operator` {
      case .or:
        interactor.connectFilterState(filterState, via: filterState[or: groupName])
      case .and:
        interactor.connectFilterState(filterState, via: SpecializedAndGroupAccessor(filterState[and: groupName]))
      }
    }
    
    public func disconnect() {
      interactor.onSelectionsComputed.cancelSubscription(for: filterState)
      filterState.onChange.cancelSubscription(for: interactor)
    }
    
  }
  
}

public extension SelectableListInteractor where Key == Item, Item: FilterType {
  
  func connectFilterState(_ filterState: FilterState,
                          operator: RefinementOperator,
                          groupName: String = "") -> FilterList.FilterStateConnection<Key> {
    let connection = FilterList.FilterStateConnection(interactor: self, filterState: filterState, operator: `operator`, groupName: groupName)
    connection.connect()
    return connection
  }
  
}

private extension SelectableListInteractor where Key == Item, Item: FilterType {
  
  func connectFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState, via accessor: Accessor) where Accessor.Filter == Key {
    whenSelectionsComputedThenUpdateFilterState(filterState, via: accessor)
    whenFilterStateChangedThenUpdateSelections(filterState, via: accessor)
  }
  
  func whenSelectionsComputedThenUpdateFilterState<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                       via accessor: Accessor) where Accessor.Filter == Item {
    
    onSelectionsComputed.subscribePast(with: filterState) { [weak self] filterState, filters in
      
      guard let interactor = self else { return }
      
      switch interactor.selectionMode {
      case .multiple:
        accessor.removeAll()
        
      case .single:
        accessor.removeAll(interactor.items)
      }
      
      accessor.addAll(filters)
      
      filterState.notifyChange()
    }
    
  }
  
  func whenFilterStateChangedThenUpdateSelections<Accessor: SpecializedGroupAccessor>(_ filterState: FilterState,
                                                                                      via accessor: Accessor) where Accessor.Filter == Item {
    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.selections = Set(accessor.filters())
    }
  }
  
}
