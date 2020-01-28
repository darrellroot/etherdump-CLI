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

var packetCount: Int32 = 0

let etherCapture: EtherCapture?
do {
    etherCapture = try EtherCapture(interface: interface, count: arguments.packetCount, command: arguments.expression) { frame in
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
    print("\(error)")
    exit(EXIT_FAILURE)
}

RunLoop.current.run()


