//
//  FilterListController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit

open class FilterListTableController<F: FilterType>: NSObject, SelectableListController, UITableViewDataSource, UITableViewDelegate {
  
  public typealias Item = F
  
  open var onClick: ((F) -> Void)?
  
  public let tableView: UITableView
  
  public var selectableItems: [SelectableItem<F>] = []
  public var filterFormatter: FilterPresenter?
  
  private let cellIdentifier = "cellID"
  
  public init(tableView: UITableView) {
    self.tableView = tableView
    super.init()
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
  }
  
  open func setSelectableItems(selectableItems: [(item: F, isSelected: Bool)]) {
    self.selectableItems = selectableItems
  }
  
  open func reload() {
    tableView.reloadData()
  }
  
  // MARK: - UITableViewDataSource
  
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return selectableItems.count
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
    let filter = selectableItems[indexPath.row]
    let filterPresenter = self.filterFormatter ?? DefaultFilterPresenter.present
    cell.textLabel?.text = filterPresenter(Filter(filter.item))
    cell.accessoryType = filter.isSelected ? .checkmark : .none
    
    return cell
  }
  
  // MARK: - UITableViewDelegate
  
  open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    onClick?(selectableItems[indexPath.row].item)
  }
  
}
