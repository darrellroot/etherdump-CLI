//
//  main.swift
//  packetCapture1
//
//  Created by Darrell Root on 1/23/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation
import PackageEtherCapture

func finish(success: Bool) -> Never {
    if success {
        exit(EXIT_SUCCESS)
    } else {
        exit(EXIT_FAILURE)
    }
}

func determineInterface(arguments: ArgumentParser) -> String {
    if let interface = arguments.interface {
        return interface
    }
    do {
        let interface = try EtherCapture.defaultInterface()
        return interface
    } catch {
        print("Error: unable to determine interface \(error)")
        exit(EXIT_FAILURE)
    }
}

guard var arguments = ArgumentParser(CommandLine.arguments) else {
    exit(EXIT_FAILURE)  // argument parser already printed out usage message
}
if arguments.help {
    arguments.usage()
    exit(EXIT_SUCCESS)
}
if arguments.version {
    arguments.printVersion()
    exit(EXIT_SUCCESS)
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

let interface = determineInterface(arguments: arguments)
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "HH:mm:ss.SSS "

var packetCount: Int32 = 0

let etherCapture: EtherCapture?
do {
    etherCapture = try EtherCapture(interface: interface, count: arguments.packetCount, command: arguments.expression, snaplen: arguments.snaplen, promiscuous: arguments.promiscuousMode) { frame in
        packetCount = packetCount + 1
        if arguments.displayPacketNumber {
            print(String(format: "%5d ",packetCount),terminator: "")
        }
        if arguments.displayTimestamp {
            print(dateFormatter.string(from: frame.date),terminator: "")
        }
        if arguments.displayLinkLayer {
            print(frame.description)
        } else {
            print(frame.layer3.description)
        }
        if arguments.displayVerboseL2 {
            print(frame.verboseDescription)
        }
        if arguments.displayVerboseL3 {
            print(frame.layer3)
        }

        
        switch (arguments.displayHexL2, arguments.displayHexL3) {
        
        case (true, false), (true, true):
            print(frame.hexdump)
        case (false, true):
            print(frame.layer3.hexdump)    // TODO
        case (false, false):
            break
        }
        
        if packetCount == arguments.packetCount {
            finish(success: true)  // does not return
        }
    }
} catch {
    print("\(error)")
    exit(EXIT_FAILURE)
}

RunLoop.current.run()


