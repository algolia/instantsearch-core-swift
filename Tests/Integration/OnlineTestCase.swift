//
//  OnlineTestCase.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
import InstantSearchClient

/// Abstract base class for online test cases.
///
class OnlineTestCase: XCTestCase {
    
    struct Task: Codable {
        let id: Int
        enum CodingKeys: String, CodingKey {
            case id = "taskID"
        }
    }
    
  var expectationTimeout: TimeInterval = 10
  
  var client: Client!
  var index: Index!
  
  let appID = Bundle(for: OnlineTestCase.self).object(forInfoDictionaryKey: "ALGOLIA_APPLICATION_ID") as? String ?? ""
  let apiKey = Bundle(for: OnlineTestCase.self).object(forInfoDictionaryKey: "ALGOLIA_API_KEY") as? String ?? ""
  
  override func setUp() {
    super.setUp()
    
    // Init client.
    client = InstantSearchClient.Client(appID: appID, apiKey: apiKey)
    
    // Init index.
    // NOTE: We use a different index name for each test function.
    let className = String(reflecting: type(of: self)).components(separatedBy: ".").last!
    let functionName = invocation!.selector.description
    let indexName = "\(className).\(functionName)"
    index = client.index(withName: safeIndexName(indexName))
    
    // Delete the index.
    // Although it's not shared with other test functions, it could remain from a previous execution.
    let expectation = self.expectation(description: "Delete index")
    client.deleteIndex(withName: index.name) { (content, error) -> Void in
      if let error = error {
        XCTFail(error.localizedDescription)
        return
      }
      guard let content = content, let taskID = content["taskID"] as? Int else {
        XCTFail("Task ID not returned for deleteIndex")
        return
      }
      self.index.waitTask(withID: taskID) { _, error in
        XCTAssertNil(error)
        expectation.fulfill()
      }
    }
    waitForExpectations(timeout: expectationTimeout, handler: nil)
  }
  
  override func tearDown() {
    super.tearDown()
    
    let expectation = self.expectation(description: "Delete index")
    client.deleteIndex(withName: index.name) { (_, error) -> Void in
      XCTAssertNil(error)
      expectation.fulfill()
    }
    waitForExpectations(timeout: expectationTimeout, handler: nil)
  }
    
    func fillIndex<O: Encodable>(withItems items: [O], settings: [String: Any], completionHandler: @escaping () -> Void) {
        
        let data = try! JSONEncoder().encode(items)
        let objects: [[String: Any]] = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String : Any]]
        
        index.saveObjects(objects) { (value, error) in
            self.extract(value, error) { (task: Task) in
                self.index.waitTask(withID: task.id) { _, _ in
                    self.index.setSettings(settings) { (value, error) in
                        self.extract(value, error) { (task: Task) in
                            self.index.waitTask(withID: task.id) { _, _ in
                                completionHandler()
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func extract<V>(_ value: [String: Any]?, _ error: Error?, success: (V) -> Void) where V: Decodable {
        switch Result<V, Error>(rawValue: value, error: error) {
        case .success(let value):
            success(value)
        case .failure(let error):
            XCTFail("\(error)")
        }
    }


    
}
