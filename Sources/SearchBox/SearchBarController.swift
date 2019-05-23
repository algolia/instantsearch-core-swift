//
//  SearchBarController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 22/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit

public class SearchBarController: NSObject, SearchableController {

  public var onSearch: ((String) -> Void)?

  let searchBar: UISearchBar

  public init(searchBar: UISearchBar) {
    self.searchBar = searchBar
    super.init()
    searchBar.delegate = self
  }

}

extension SearchBarController: UISearchBarDelegate {

  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    onSearch?(searchText)
  }

}
