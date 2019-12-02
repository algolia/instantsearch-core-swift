//
//  ConnectionHandler.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 26/11/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class ConnectionHandler: Connection {
  
  public var connections: [Connection]
  
  public init(connections: [Connection] = []) {
    self.connections = connections
    connect()
  }
  
  public func connect() {
    connections.forEach { $0.connect() }
  }
  
  public func disconnect() {
    connections.forEach { $0.disconnect() }
  }
  
}
