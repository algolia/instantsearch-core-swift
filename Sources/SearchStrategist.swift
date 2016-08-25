//
//  Copyright (c) 2016 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AlgoliaSearch
import Foundation


/// A `SearchStrategist` constantly monitors the response time of a `Searcher`'s requests, and adapts its strategy
/// accordingly.
///
/// Usage is rather straightforward: init the strategist with a searcher, then call `SearchStrategist.search(_:)`
/// instead of `Searcher.search()`. The strategist will monitor requests and adapt its strategy dynamically.
///
/// The rest goes on pretty much automatically. However, you may want to observe the current strategy, as well as
/// dropped requests (see below) to provide user feedback in your UI.
///
/// # Configuration
///
/// The strategy computation is based on several settings:
///
/// - `amnesiaDelay`
/// - `throttleThreshold`
/// - `manualThreshold`
/// - `maxRequestsInHistory`
///
/// # Observing
///
/// ## KVO
///
/// The following properties are observable via KVO:
///
/// - `strategy`: the current strategy.
///
/// ## Notifications
///
/// The following notifications are posted:
///
/// - `DropNotification`: when a request is dropped (as-you-type requests in `Manual` strategy).
///
@objc public class SearchStrategist: NSObject {
    /// The searchers used by this strategist.
    @objc public private(set) var searchers: [Searcher] = []
    
    /// Debouncer used for the throttled mode. You may adjust its `delay` property if you wish.
    @objc public let debouncer = Debouncer(delay: 0.5)
    
    /// Requests older than this delay will be discarded from the statistics.
    @objc public var amnesiaDelay: NSTimeInterval = 20
    
    /// Maximum number of requests that will be considered for the statistics. Always the N most recent ones are used.
    @objc public var maxRequestsInHistory: Int = 3

    /// Threshold beyond which throttled mode is activated.
    @objc public var throttleThreshold: NSTimeInterval = 0.5
    
    /// Threshold beyond which manual mode is activated.
    @objc public var manualThreshold: NSTimeInterval = 3.0
    
    /// Possible search strategies.
    @objc public enum Strategy: Int {
        /// As-you-type search in realtime: every keystroke immediately triggers a request.
        case Realtime = 1
        
        /// As-you-type search with throttling: requests are slightly delayed and merged if necessary, to avoid spawning
        /// too many of them.
        case Throttled = 2
        
        /// Search has to be explicitly triggered by the user.
        case Manual = 3
    }
    
    /// The current strategy.
    ///
    /// + Note: KVO-observable.
    ///
    @objc public private(set) var strategy: Strategy = .Realtime {
        willSet(newValue) {
            if newValue != strategy {
                self.willChangeValueForKey("strategy")
            }
        }
        didSet(oldValue) {
            if oldValue != strategy {
                #if DEBUG
                    NSLog("New strategy: \(strategy.rawValue)")
                #endif
                self.didChangeValueForKey("strategy")
            }
        }
    }
    
    /// Statistics about a single request.
    private struct RequestStat: CustomStringConvertible {
        /// The request's sequence number.
        let seqNo: Int
        
        /// The request's start date.
        let startDate: NSDate
        
        /// The request's stop date, or `nil` if the request is still running.
        var stopDate: NSDate? = nil
        
        /// The request's duration.
        var duration: NSTimeInterval { return (stopDate ?? NSDate()).timeIntervalSinceDate(startDate) }
        
        /// Whether the request is still running.
        var running: Bool { return stopDate == nil }
        
        /// Whether the request was cancelled.
        var cancelled: Bool = false
        
        /// Whether the request was completed.
        var completed: Bool { return !running && !cancelled }
        
        var description: String {
            return "RequestStat{seqNo=\(seqNo), startDate=\(startDate), duration=\(duration), running=\(running), cancelled=\(cancelled)}"
        }
    }
    
    /// Current statistics.
    private var stats: [RequestStat] = []
    
    // MARK: - Initialization
    
    /// Construct a new empty strategist.
    ///
    /// + Warning: You should add at least one `Searcher`, otherwise the `search(_:)` method will do nothing.
    ///
    @objc public override init() {
    }
    
    /// Construct a new strategist, using the specified searcher.
    ///
    /// - parameter searcher: Searcher to be used.
    ///
    @objc public convenience init(searcher: Searcher) {
        self.init()
        addSearcher(searcher)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    /// Add a new searcher to this strategist.
    ///
    /// - parameter searcher: The searcher to add.
    ///
    @objc public func addSearcher(searcher: Searcher) {
        searchers.append(searcher)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(self.searchEvent), name: nil, object: searcher)
    }
    
    /// Remove a searcher from this strategist.
    ///
    /// - parameter searcher: The searcher to remove.
    ///
    @objc public func removeSearcher(searcher: Searcher) {
        if let index = searchers.indexOf(searcher) {
            searchers.removeAtIndex(index)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: nil, object: searcher)
        }
    }
    
    /// Clear the request history.
    @objc public func clearHistory() {
        stats.removeAll()
    }
    
    // MARK: - Search
    
    /// Launch a search.
    ///
    /// - parameter asYouType: If `true`, will be considered an as-you-type search and eligible for the current
    ///   strategy. When `false`, will disregard the strategy and launch a request anyway. Use this for example when
    ///   the user hits the "Search" button, or refines a facet; or for programmatic (non-user initiated) searches.
    ///
    @objc public func search(asYouType: Bool = false) {
        if !asYouType {
            _search()
        } else {
            updateStrategy()
            switch strategy {
            case .Realtime:
                _search()
                break
            case .Throttled:
                debouncer.call({
                    self._search()
                })
                break
            case .Manual:
                // Inform observers that a request has been dropped.
                NSNotificationCenter.defaultCenter().postNotificationName(SearchStrategist.DropNotification, object: self, userInfo: nil)
                break
            }
        }
    }
    
    private func _search() {
        for searcher in searchers {
            searcher.search()
        }
    }
    
    // MARK: - Events
    
    @objc private func searchEvent(notification: NSNotification) {
        guard let requestSeqNo = notification.userInfo?[Searcher.NotificationSeqNoKey] as? Int else { return }

        switch notification.name {
        case Searcher.SearchNotification:
            #if DEBUG
            if let query = (notification.userInfo?[Searcher.NotificationQueryKey] as? Query)?.query {
                NSLog("SEARCH: \"\(query)\"")
            }
            #endif
            
            // Mark start time.
            stats.append(RequestStat(seqNo: requestSeqNo, startDate: NSDate(), stopDate: nil, cancelled: false))
            
            // Schedule to check the request after the various thresholds.
            // Why? If the request takes a long time, we want to react *before* the response is actually received
            // (which may take many seconds in case of time out).
            let checkPendingRequestsBlock = {
                [weak self] in
                guard let this = self else { return }
                if !this.stats.filter({ $0.running }).isEmpty {
                    this.updateStrategy()
                }
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(throttleThreshold * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), checkPendingRequestsBlock)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(manualThreshold * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), checkPendingRequestsBlock)
            break
            
        case Searcher.ResultNotification, Searcher.ErrorNotification, Searcher.CancelNotification:
            guard let statIndex = stats.indexOf({ $0.seqNo == requestSeqNo }) else { return }
            stats[statIndex].stopDate = NSDate()
            // Cancelled requests are tricky: we don't know what would have been their duration.
            // We sometimes want to ignore them, sometimes not. => We store the cancelled status and let the
            // algorithm decide.
            if notification.name == Searcher.CancelNotification {
                stats[statIndex].cancelled = true
            }
            updateStrategy()
            break
            
        default:
            break // ignore
        }
    }
    
    /// Update the strategy based on the current stats.
    private func updateStrategy() {
        // Remove old stats.
        let now = NSDate()
        stats = stats.filter({ $0.running || now.timeIntervalSinceDate($0.stopDate!) < amnesiaDelay })

        // Compute average duration
        // ------------------------
        // We have a dilemma here:
        // - Short non-completed requests (still running or cancelled) do not mean the response time is good...
        // - ... but long non-completed requests do mean that the response time is bad!
        //
        // => We compute two values, (1) for completed requests and (2) for all requests, and take the worst one.
        //
        let overallStats = stats.suffix(maxRequestsInHistory)
        let completedStats = stats.filter({ $0.completed }).suffix(maxRequestsInHistory)
        func avg(slice: ArraySlice<RequestStat>) -> NSTimeInterval {
            return slice.isEmpty ? 0.0 : slice.reduce(0.0) { $0 + $1.duration } / Double(slice.count)
        }
        let overallAverageDuration = avg(overallStats)
        let completedAverageDuration = avg(completedStats)
        let worstAverageDuration = max(overallAverageDuration, completedAverageDuration)
        
        let lastDuration = stats.last?.duration ?? 0.0
        let lastCompleted = stats.last?.completed ?? false
        #if DEBUG
            NSLog("Request history: \(stats)")
            NSLog("AVG: overall=\(overallAverageDuration), completed=\(completedAverageDuration); LAST: \(lastDuration)")
        #endif
        
        // Choose the strategy.
        //
        // NOTE: One last good duration is enough to consider that realtime conditions are back. This optimistic
        // algorithm allows to react immediately when good network is back.
        //
        // CAUTION: Non-completed requests do no count.
        //
        if (lastCompleted && lastDuration < throttleThreshold) || worstAverageDuration < throttleThreshold {
            strategy = .Realtime
        }
        // Otherwise, if average duration is within acceptable bounds, use throttled mode.
        else if worstAverageDuration < manualThreshold {
            strategy = .Throttled
        }
        // Out of desperation, revert to manual mode.
        else {
            strategy = .Manual
        }
    }
    
    // MARK: - Notifications
    
    /// Notification posted when a request is dropped (only occurs in `Manual` strategy).
    @objc public static let DropNotification: String = "drop"
}
