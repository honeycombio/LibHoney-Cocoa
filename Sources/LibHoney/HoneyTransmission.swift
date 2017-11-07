//
//  HoneyTransmission.swift
//  LibHoney-Swift
//
//  Created by Chong Han Chua on 11/6/17.
//

import Foundation
import Alamofire
import os.log

/// The endpoint identifier is a datastructure that provides a unique identifier
/// for an endpoint consisting of the hostAPI, write key and dataset
private struct EndpointIdentifier: Hashable {
    static func ==(lhs: EndpointIdentifier, rhs: EndpointIdentifier) -> Bool {
        return lhs.hostAPI == rhs.hostAPI && lhs.writeKey == rhs.writeKey && lhs.dataset == rhs.dataset
    }
    
    let hostAPI: String
    let writeKey: String
    let dataset: String
    
    var hashValue: Int {
        return (hostAPI + writeKey + dataset).hashValue
    }
}


private struct EventJSON: Codable {
    let timestamp: String
    let samplerate: UInt
    let data: [String: HoneyEventType]
}


class HTTPRetryHandler: RequestRetrier {
    
    let maxAttempts = 4
    var attempts = 0
    
    func should(_ manager: SessionManager, retry request: Request, with error: Error, completion: @escaping RequestRetryCompletion) {
        
        let delay = Double(attempts)
        attempts += 1
        
        if let response = request.task?.response as? HTTPURLResponse,
            response.statusCode > 200 && response.statusCode < 300 {
            // Success
            completion(false, 0.0)
        } else if attempts > maxAttempts {
            // Giving up
            completion(false, 0.0)
        } else {
            // We are going to retry after the delay
            completion(true, delay)
        }
    }
    
}

/// The transmission class for LibHoney
class HoneyTransmission {
    // Private internal even queues
    private var eventQueues: [EndpointIdentifier: [HoneyEvent]] = [:]
    private var timerHashMap: [EndpointIdentifier: DispatchSourceTimer] = [:]
    private let transmissionQueue = DispatchQueue(label: "io.honeycomb.libHoneySwift.transmissionQueue")
    
    // Configuration properties
    let maxBatchSize: UInt
    let sendFrequency: TimeInterval
    var mockEndpoint: ((URLRequest) -> Void)? // This is used for unit testing purposes only
    
    let formatter = ISO8601DateFormatter()
    
    init(maxBatchSize: UInt, sendFrequency: TimeInterval, mockEndpoint: ((URLRequest) -> ())? = nil) {
        self.maxBatchSize = maxBatchSize
        self.sendFrequency = sendFrequency
        self.mockEndpoint = mockEndpoint
    }
    
    func enqueue(event: HoneyEvent) {
        
        guard event.writeKey != nil && event.dataset != nil else {
            os_log("The event was discarded because it does not contain a valid writeKey or dataset", type: .error)
            return
        }
        
        transmissionQueue.async { [weak self] in
            self?.writeEvent(event: event)
        }
    }
 
    func flush() {
        transmissionQueue.async { [weak self] in
            if let s = self {
                for (endpointId, _) in s.eventQueues {
                    s.sendIfNecessary(endpointId: endpointId)
                }
            }
        }
    }
    
    // This method must only be called inside the transmission queue
    private func writeEvent(event: HoneyEvent) {
        let apiHost = event.apiHost
        guard let writeKey = event.writeKey,
            let dataset = event.dataset else {
                os_log("writeKey or dataset is not set: %@ and %@", type: .error,
                       String(describing: event.writeKey),
                       String(describing: event.dataset))
                return
        }
        
        let endpointId = EndpointIdentifier(hostAPI: apiHost, writeKey: writeKey, dataset: dataset)
        
        if (eventQueues[endpointId] == nil) {
            eventQueues[endpointId] = []
        }
        
        eventQueues[endpointId]?.append(event)
        
        let queueCount = eventQueues[endpointId]?.count ?? 0
        
        if queueCount >= maxBatchSize {
            sendIfNecessary(endpointId: endpointId)
        } else if timerHashMap[endpointId] == nil  {
            let timer = getLater(deadline: .now() + sendFrequency, handler: {
                [weak self] in
                self?.sendIfNecessary(endpointId: endpointId)
            })
            timerHashMap[endpointId] = timer
        }
    }
    
    // This method must only be called inside the transmission queue
    private func sendIfNecessary(endpointId: EndpointIdentifier) {
        
        var urlComponents = URLComponents(string: endpointId.hostAPI)
        urlComponents?.path = "/1/batch/" + endpointId.dataset
        guard let url = urlComponents?.url else {
            os_log("Unable to parse url from urlcomponents: %@", type: .error,
                   String(describing: urlComponents?.description))
            return
        }
        
        guard let dataQueue = eventQueues[endpointId] else {
            os_log("Unable to get event queue for endpoint: %@", type: .error,
                   String(describing: endpointId.dataset))
            return
        }
        
        guard dataQueue.count > 0 else {
            os_log("No queries to send: %@", endpointId.dataset)
            return
        }
        
        // Transform the data to the desired output format
        let dataArray = dataQueue.map { (event) -> EventJSON in
            return EventJSON(timestamp: formatter.string(from: event.timestamp),
                             samplerate: event.sampleRate, data: event.data)
        }
        
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(dataArray) else {
            os_log("Unable to encode json: %@", type: .error, dataArray)
            return
        }
        
        // We remove the current data so it does not get sent multiple times
        // If send failed, we'll just have to retry it in block
        eventQueues[endpointId]?.removeAll()

        let headers: HTTPHeaders = [
            "X-Honeycomb-Team": endpointId.writeKey,
            "Content-Type": "application/json",
            "User-Agent": "libhoney-swift/1.0.0",
        ]
        
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = headers
        urlRequest.httpMethod = "POST"
        urlRequest.httpBody = data
        
        if let endpoint = mockEndpoint {
            endpoint(urlRequest)
        } else {
            let sessionManager = Alamofire.SessionManager.default
            sessionManager.retrier = HTTPRetryHandler()
            sessionManager.request(urlRequest).responseData(completionHandler: { (response) in
                if case let .failure(error) = response.result {
                    os_log("Error sending: %@", type: .error, error.localizedDescription)
                }
            })
        }

        // Losing the strong reference to the timer invaldiates the timer
        timerHashMap[endpointId] = nil
    }
    
    private func getLater(deadline: DispatchTime,
                          handler: @escaping () -> Void) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(queue: transmissionQueue)
        timer.schedule(deadline: deadline, repeating: .infinity)
        timer.setEventHandler {
            handler()
        }
        timer.resume()
        return timer
    }
    
}
