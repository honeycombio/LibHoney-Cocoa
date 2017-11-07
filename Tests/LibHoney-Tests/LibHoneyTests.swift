import XCTest
@testable import LibHoney

class LibHoneyTests: XCTestCase {

    func testLibHoneyConfigure() {
        let writeKey = "fdf194ec-ea64-485b-a662-f639eb184fc7"
        let dataset = "honeycombio-swift-test"
        LibHoney.configure(writeKey: writeKey, dataset: dataset)
        
        XCTAssert(LibHoney.shared?.config.writeKey == writeKey)
    }
    
    func testGlobalEvent() {
        let writeKey = "fdf194ec-ea64-485b-a662-f639eb184fc7"
        let dataset = "honeycombio-swift-test"
        LibHoney.configure(writeKey: writeKey, dataset: dataset)
        
        let newEvent = LibHoney.shared?.newEvent()
        if let newEvent = newEvent {
            let foobar1 = newEvent.data["foobar"]
            XCTAssert(foobar1 == nil)
        } else {
            XCTFail()
        }
        
        LibHoney.shared?.add(key: "foobar", value: 2017)
        let newEvent2 = LibHoney.shared?.newEvent()
        if let event = newEvent2, let foobar = event.data["foobar"] {
            XCTAssert(foobar == .int(2017))
        } else {
            XCTFail()
        }
    }
    
    func testSend() {
        let expectation = XCTestExpectation(description: "Fires in 0.1 seconds")
        
        let writeKey = "fdf194ec-ea64-485b-a662-f639eb184fc7"
        let dataset = "honeycombio-swift-test"
        LibHoney.configure(writeKey: writeKey, dataset: dataset)
        LibHoney.shared?.transmission.mockEndpoint = { _ in
            expectation.fulfill()
        }
        
        let newEvent = LibHoney.shared?.newEvent()
        newEvent?.add(key: "test", value: false)
        LibHoney.shared?.send(newEvent)
        
        wait(for: [expectation], timeout: 3.0)
    }
    
    struct JSONStub: Decodable {
        let timestamp: String
    }
    
    func testSendSampling() {
        let expectation = XCTestExpectation(description: "Fires in 0.1 seconds")
        
        let length = 5
        let writeKey = "fdf194ec-ea64-485b-a662-f639eb184fc7"
        let dataset = "honeycombio-swift-test"
        LibHoney.configure(writeKey: writeKey, dataset: dataset)
        LibHoney.shared?.transmission.mockEndpoint = { request in
            if let data = request.httpBody {
                let decoder = JSONDecoder()
                if let json = try? decoder.decode([JSONStub].self, from: data) {
                    XCTAssert(json.count < length)
                    expectation.fulfill()
                }
            }
        }
        
        for _ in 0 ..< length {
            let newEvent = LibHoney.shared?.newEvent()
            newEvent?.sampleRate = 3
            newEvent?.add(key: "test", value: false)
            LibHoney.shared?.send(newEvent)
        }
        
        let result = XCTWaiter.wait(for: [expectation], timeout: 1.0)
    }
    
}
