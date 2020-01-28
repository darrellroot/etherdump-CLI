//
//  main.swift
//  packetCapture1
//
//  Created by Darrell Root on 1/23/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation
import PackageEtherCapture

func finish(success: Bool) {
    if success {
        exit(EXIT_SUCCESS)
    } else {
        exit(EXIT_FAILURE)
    }
}

guard var arguments = ArgumentParser(CommandLine.arguments) else {
    exit(EXIT_FAILURE)  // argument parser already printed out usage message
}
if arguments.listAllInterfaces {
    if let interfaces = EtherCapture.listInterfaces() {
        for interface in interfaces {
            print(interface)
        }
        exit(EXIT_SUCCESS)
    } else {
        print("Error: Unable to detect interfaces")
        exit(EXIT_FAILURE)
    }
}

var packetCount: Int32 = 0

let etherCapture: EtherCapture?
do {
    etherCapture = try EtherCapture(interface: "en0", count: arguments.packetCount, command: arguments.expression) { frame in
        if arguments.displayLinkLayer {
            debugPrint(frame.description)
        } else {
            debugPrint(frame.contents.description)
        }
        
        packetCount = packetCount + 1
        if packetCount == arguments.packetCount {
            finish(success: true)
        }
    }
} catch {
    print("EtherCapture initialization failed with error \(error)")
}

RunLoop.current.run()


