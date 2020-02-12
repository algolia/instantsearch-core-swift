//
//  Logging.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 11/02/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation
import Logging

typealias SwiftLog = Logging.Logger

struct Logger {
  
  static var loggingService: Loggable = SwiftLog(label: "com.algolia.InstantSearch")
  
  private init() {}
  
  static func trace(_ message: String) {
    loggingService.log(level: .trace, message: message)
  }
  
  static func debug(_ message: String) {
    loggingService.log(level: .debug, message: message)
  }
  
  static func info(_ message: String) {
    loggingService.log(level: .info, message: message)
  }
  
  static func notice(_ message: String) {
    loggingService.log(level: .notice, message: message)
  }
  
  static func warning(_ message: String) {
    loggingService.log(level: .warning, message: message)
  }
  
  static func error(_ message: String) {
    loggingService.log(level: .error, message: message)
  }
  
  static func critical(_ message: String) {
    loggingService.log(level: .critical, message: message)
  }
  
}

enum LogLevel {
  case trace, debug, info, notice, warning, error, critical
}

extension Logger {
    
  static func error(prefix: String = "", _ error: Error) {
    let errorMessage: String
    if let decodingError = error as? DecodingError {
      errorMessage = DecodingErrorPrettyPrinter(decodingError: decodingError).description
    } else {
      errorMessage = "\(error)"
    }
    self.error("\(prefix) \(errorMessage)")
  }
  
  static func resultsReceived(fromIndexWithName indexName: String, results: SearchResults) {
    let query = results.stats.query ?? ""
    let message = "received results - index: \(indexName) query: \"\(query)\" hits count: \(results.stats.totalHitsCount) in \(results.stats.processingTimeMS)ms"
    self.info(message)
  }
  
}

extension LogLevel {
  
  var swiftLogLevel: SwiftLog.Level {
    switch self {
    case .trace: return .trace
    case .debug: return .debug
    case .info: return .info
    case .notice: return .notice
    case .warning: return .warning
    case .error: return .error
    case .critical: return .critical
    }
  }
  
}

protocol Loggable {
  
  func log(level: LogLevel, message: String)
  
}

extension SwiftLog: Loggable {
  
  func log(level: LogLevel, message: String) {
    self.log(level: level.swiftLogLevel, SwiftLog.Message(stringLiteral: message), metadata: .none)
  }
  
}
