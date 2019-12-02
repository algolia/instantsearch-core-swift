//
//  HitsConnector.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 29/11/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class HitsConnector<Hit: Codable>: Connection {
    
  public let searcher: Searcher
  public let filterState: FilterState
  public let interactor: HitsInteractor<Hit>
  
  public let filterStateConnection: Connection
  public let searcherConnection: Connection
  
  internal init<S: Searcher>(searcher: S, filterState: FilterState, interactor: HitsInteractor<Hit>, connectSearcher: (S) -> Connection) {
    self.searcher = searcher
    self.filterState = filterState
    self.interactor = interactor
    self.filterStateConnection = interactor.connectFilterState(filterState)
    self.searcherConnection = connectSearcher(searcher)
  }
  
  public convenience init(searcher: SingleIndexSearcher,
              filterState: FilterState,
              interactor: HitsInteractor<Hit>) {
    self.init(searcher: searcher,
              filterState: filterState,
              interactor: interactor,
              connectSearcher: interactor.connectSearcher)
  }
  
  
  public func connect() {
    filterStateConnection.connect()
    searcherConnection.connect()
  }
  
  public func disconnect() {
    filterStateConnection.disconnect()
    searcherConnection.disconnect()
  }
  
}

extension HitsConnector where Hit == InstantSearchCore.Hit<Place> {
  
  public convenience init(searcher: PlacesSearcher,
                          filterState: FilterState,
                          interactor: HitsInteractor<Hit>) {
    self.init(searcher: searcher,
              filterState: filterState,
              interactor: interactor,
              connectSearcher: interactor.connectPlacesSearcher)
  }
  
}
