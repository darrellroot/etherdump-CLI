//
//  etherdump_test.swift
//  etherdump-test
//
//  Created by Darrell Root on 2/3/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import XCTest
import PackageSwiftPcapng
import PackageEtherCapture

class etherdump_test: XCTestCase {
    var arguments = ArgumentParser(["etherdump","-xx","-v2","-v3","-v4"])!
    override func setUp() {

        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {
        let bundle = Bundle(for: type(of: self))
        guard let fileUrl = bundle.url(forResource: "test001", withExtension: "pcapng"), let data = try? Data(contentsOf: fileUrl) else {
            XCTFail()
            return
        }
        XCTAssert(data.count > 0)
        let pcapng = Pcapng(data: data)
        guard let packetBlocks = pcapng?.segments.first?.packetBlocks else {
            print("Error: unable to get packets from decoding PCAPNG file \(fileUrl)")
            XCTFail()
            return
        }
        for (count,packet) in packetBlocks.enumerated() {
            let frame = Frame(data: packet.packetData)
            displayFrame(frame: frame, packetCount: Int32(count), arguments: arguments)
        }
        
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
