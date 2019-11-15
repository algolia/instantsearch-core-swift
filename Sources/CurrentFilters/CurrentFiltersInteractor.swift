//
//  CurrentFiltersInteractor.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 12/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public typealias CurrentFiltersInteractor = ItemsListInteractor<FilterAndID>

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

public extension CurrentFiltersInteractor {

  func connectFilterState(_ filterState: FilterState,
                          filterGroupID: FilterGroup.ID?) {
    if let filterGroupID = filterGroupID {
      connectFilterState(filterState, filterGroupIDs: Set([filterGroupID]))
    } else {
      connectFilterState(filterState)
    }

  }

  func connectFilterState(_ filterState: FilterState,
                          filterGroupIDs: Set<FilterGroup.ID>? = nil) {

    filterState.onChange.subscribePast(with: self) { [weak filterState] interactor, _  in
      guard let filterState = filterState else { return }
      if let filterGroupIDs = filterGroupIDs {
        interactor.items = filterState.getFiltersAndID().filter { filterGroupIDs.contains($0.id) }
      } else {
        interactor.items = filterState.getFiltersAndID()
      }
    }

    onItemsComputed.subscribePast(with: self) { [weak filterState] _, items in

      guard let filterState = filterState else { return }

      if let filterGroupIDs = filterGroupIDs {
        filterState.filters.removeAll(fromGroupWithIDs: Array(filterGroupIDs))
        items.forEach({ (filterAndID) in
          filterState.filters.add(filterAndID.filter.filter, toGroupWithID: filterAndID.id)
        })
      } else {
        filterState.filters.removeAll()
        items.forEach({ (filterAndID) in
          filterState.filters.add(filterAndID.filter.filter, toGroupWithID: filterAndID.id)
        })
      }

      filterState.notifyChange()
    }
  }

  func connectFilterState(_ filterState: FilterState,
                          filterGroupID: FilterGroup.ID) {
    
    connectFilterState(filterState, filterGroupIDs: Set([filterGroupID]))
  }
}

public extension ItemsListInteractor {

  func connectController<C: ItemListController>(_ controller: C,
                                                presenter: @escaping Presenter<Filter, String> = DefaultPresenter.Filter.present) where C.Item == Item, Item == FilterAndID {

    controller.onRemoveItem = { [weak self] item in
      let filterAndID = FilterAndID(filter: item.filter, id: item.id)
      self?.remove(item: filterAndID)
    }

    onItemsChanged.subscribePast(with: controller) { controller, items in
      let itemsWithPresenterApplied = items.map { FilterAndID(filter: $0.filter, id: $0.id, text: presenter($0.filter))}
      controller.setItems(itemsWithPresenterApplied)
      controller.reload()
    }.onQueue(.main)
  }
}
