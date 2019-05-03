//
//  SelectableViewModel.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 03/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class SelectableViewModel<Item> {
  
  public let item: Item
  public var isSelected: Bool {
    didSet {
      onSelectedChanged.fire(isSelected)
    }
  }
  public var onSelectedChanged: Observer<Bool>
  public var onSelectedComputed: Observer<Bool>

  init(item: Item) {
    self.item = item
    self.isSelected = false
    self.onSelectedChanged = Observer()
    self.onSelectedComputed = Observer()
  }
  
  func setSelected(_ isSelected: Bool) {
    onSelectedComputed.fire(isSelected)
  }
  
}

extension SelectableViewModel where Item: FilterType {
  
  func connectSearcher<R: Codable>(_ searcher: SingleIndexSearcher<R>,
                                   operator: RefinementOperator = .or,
                                   groupName: String? = nil) {
    
    updateQueryFacets(of: searcher, with: item.attribute)
    
    let groupID = self.groupID(with: `operator`, attribute: item.attribute, groupName: groupName)

    whenSelectionsComputedThenUpdateFilterState(item.attribute, searcher, groupID)
    
    whenFilterStateChangedThenUpdateSelections(of: searcher, groupID: groupID)
  }
  
  func connectViewController<VC: SelectableViewController>(_ viewController: VC) {
    viewController.setSelected(isSelected)
    viewController.onClick = { [weak self] isSelected in
      self?.setSelected(isSelected)
    }
    onSelectedChanged.subscribe(with: viewController) { isSelected in
      viewController.setSelected(isSelected)
    }
  }
  
}

fileprivate extension SelectableViewModel where Item: FilterType {
  
  func updateQueryFacets<R: Codable>(of searcher: SingleIndexSearcher<R>, with attribute: Attribute) {
    
    guard let facets = searcher.indexSearchData.query.facets else {
      searcher.indexSearchData.query.facets = [attribute.name]
      
      return
    }
    
    guard facets.contains(attribute.name) else {
      searcher.indexSearchData.query.facets! += [attribute.name]
      
      return
    }
  }
  
  func whenSelectionsComputedThenUpdateFilterState<R: Codable>(_ attribute: Attribute, _ searcher: SingleIndexSearcher<R>, _ groupID: FilterGroup.ID) {
    
    onSelectedComputed.subscribe(with: self) { [weak self] selected in
      
      guard let item = self?.item else { return }
      
      searcher.indexSearchData.filterState.notify { filterState in
        if selected {
          filterState.add(item, toGroupWithID: groupID)
        } else {
          filterState.remove(item)
        }
      }
      
    }
  }
  
  func groupID(with operator: RefinementOperator, attribute: Attribute, groupName: String?) -> FilterGroup.ID {
    switch `operator` {
    case .and:
      return .and(name: groupName ?? attribute.name)
    case .or:
      return .or(name: groupName ?? attribute.name)
    }
  }
  
  func whenFilterStateChangedThenUpdateSelections<R: Codable>(of searcher: SingleIndexSearcher<R>, groupID: FilterGroup.ID) {
    let onChange: (FiltersReadable) -> Void = { [weak self] filterState in
      guard let filter = self?.item else { return }
      self?.isSelected = filterState.contains(filter, inGroupWithID: groupID)
    }
    
    onChange(searcher.indexSearchData.filterState)
    
    searcher.indexSearchData.filterState.onChange.subscribe(with: self, callback: onChange)
  }
  
}
