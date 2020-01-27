//
//  main.swift
//  packetCapture1
//
//  Created by Darrell Root on 1/23/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation
import PackageEtherCapture

print("Hello, World!")

guard let etherCapture = EtherCapture(interface: "en0", command: "") else {
    fatalError("failed to initialize SwiftPcap")
}

DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
    var done = false
    repeat {
        if let frame = etherCapture.nextPacket() {
            debugPrint(frame.description)
        } else {
            done = true
        }
    } while !done
}
RunLoop.current.run()
