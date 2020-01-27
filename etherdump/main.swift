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

let etherCapture: EtherCapture?
do {
    etherCapture = try EtherCapture(interface: "en0", command: "icfwemp or icmp6") { frame in
        debugPrint(frame.description)
    }
} catch {
    print("EtherCapture initialization failed with error \(error)")
}

//etherCapture.setCallback(gotFrame(frame:))


/*DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
    var done = false
    repeat {
        if let frame = etherCapture.nextPacket() {
            debugPrint(frame.description)
        } else {
            done = true
        }
    } while !done
}*/
RunLoop.current.run()
