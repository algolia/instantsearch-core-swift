//
//  CurrentFiltersViewModel.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias CurrentFiltersViewModel = ItemsListViewModel<FilterAndID>

public struct FilterAndID: Hashable {
  public let filter: Filter
  public let id: FilterGroup.ID
}

public struct TextAndID: Hashable {
  public let text: String
  public let id: FilterGroup.ID
}

public extension CurrentFiltersViewModel {
  
  func connectFilterState(_ filterState: FilterState, filterGroupID: FilterGroup.ID? = nil) {
    
    filterState.onChange.subscribePast(with: self) { [weak self](filters) in
      if let filterGroupID = filterGroupID {
        self?.items = Set(filters.getFilters(forGroupWithID: filterGroupID).map { FilterAndID(filter: $0, id: filterGroupID) })
      } else {
        self?.items = filters.getFiltersAndID()
      }
    }

    onItemsComputed.subscribePast(with: self) { (items) in

      if let filterGroupID = filterGroupID {
        filterState.filters.removeAll(fromGroupWithID: filterGroupID)
        filterState.filters.addAll(filters: items.map { $0.filter.filter }, toGroupWithID: filterGroupID)
      } else {
        filterState.filters.removeAll()
        items.forEach({ (filterAndID) in
          filterState.filters.add(filterAndID.filter.filter, toGroupWithID: filterAndID.id)
        })
      }

      filterState.notifyChange()
    }
  }
}

public extension ItemsListViewModel {

  func connectController<C: ItemListController>(_ controller: C) where C.Item == Item {
    controller.onRemoveItem = self.remove(item:)

    onItemsChanged.subscribePast(with: controller) { (items) in
      controller.setItems(items)
      controller.reload()
    }

  }
}
