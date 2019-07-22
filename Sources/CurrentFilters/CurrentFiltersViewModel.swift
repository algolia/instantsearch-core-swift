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
  public var text: String

  public init(filter: Filter, id: FilterGroup.ID, text: String = "") {
    self.filter = filter
    self.id = id
    self.text = text
  }
}

public extension CurrentFiltersViewModel {
  
  func connectFilterState(_ filterState: FilterState,
                          filterGroupID: FilterGroup.ID? = nil) {
    
    filterState.onChange.subscribePast(with: self) { [weak self, weak filterState] _ in
      guard let filterState = filterState else { return }
      if let filterGroupID = filterGroupID {
        self?.items = Set(filterState.getFilters(forGroupWithID: filterGroupID).map { FilterAndID(filter: $0, id: filterGroupID) })
      } else {
        self?.items = filterState.getFiltersAndID()
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

  func connectController<C: ItemListController>(_ controller: C, presenter: Presenter<Filter, String>? = nil) where C.Item == Item, Item == FilterAndID {

    let filterPresenter = presenter ?? DefaultPresenter.Filter.present

    controller.onRemoveItem = { item in
      let filterAndID = FilterAndID(filter: item.filter, id: item.id)
      self.remove(item: filterAndID)
    }

    onItemsChanged.subscribePast(with: controller) { (items) in
      let itemsWithPresenterApplied = items.map { FilterAndID(filter: $0.filter, id: $0.id, text: filterPresenter($0.filter))}
      controller.setItems(itemsWithPresenterApplied)
      controller.reload()
    }
  }
}
