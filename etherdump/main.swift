//
//  main.swift
//  packetCapture1
//
//  Created by Darrell Root on 1/23/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation
import PackageEtherCapture
import PackageSwiftPcapng
import Logging

var frames: [Frame] = []
func determineInterface(arguments: ArgumentParser) -> String {
    if let interface = arguments.interface {
        return interface
    }
    do {
        let interface = try EtherCapture.defaultInterface()
        return interface
    } catch {
        print("Error: unable to determine interface \(error) defaulting to en0")
        return "en0"
    }
}

guard var arguments = ArgumentParser(CommandLine.arguments) else {
    exit(EXIT_FAILURE)  // argument parser already printed out usage message
}

LoggingSystem.bootstrap(DarrellLogHandler.init)
if arguments.verboseLogging {
    Pcapng.logger.logLevel = .info
    EtherCapture.logger.logLevel = .info
} else {
    Pcapng.logger.logLevel = .error
    EtherCapture.logger.logLevel = .error
}

func finish(success: Bool) -> Never {
    if success {
        if let filename = arguments.writeFileJson {
            let encoder = JSONEncoder()
            let fileManager = FileManager()
            let encodedFrames: Data
            do {
                encodedFrames = try encoder.encode(frames)
            } catch {
                print("Error failed to encode frames error \(error)")
                exit(EXIT_FAILURE)
            }
            let path = fileManager.currentDirectoryPath
            let url = URL(fileURLWithPath: path).appendingPathComponent(filename)
            do {
                try encodedFrames.write(to: url)
            } catch {
                print("Error failed to write file url \(url) error \(error)")
                exit(EXIT_FAILURE)
            }
        }
        exit(EXIT_SUCCESS)
    } else {
        exit(EXIT_FAILURE)
    }
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

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "HH:mm:ss.SSS "

var packetCount: Int32 = 0

func displayFrame(frame: Frame, packetCount: Int32, arguments: ArgumentParser) {
    if arguments.writeFileJson != nil {
        frames.append(frame)
    }
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
        print("  ",frame.verboseDescription)
    }
    if arguments.displayVerboseL3 {
        print("    ",frame.layer3.verboseDescription)
    }

    if arguments.displayVerboseL4 {
        if let layer4 = frame.layer4 {
            print("      ",layer4.verboseDescription)
        }
    }
    
    switch (arguments.displayHexL2, arguments.displayHexL3) {
    
    case (true, false), (true, true):
        print(frame.hexdump)
    case (false, true):
        print(frame.layer3.hexdump)    // TODO
    case (false, false):
        break
    }
}

if let readFile = arguments.readFileJson {
    guard let url = Bundle.main.url(forResource: readFile, withExtension: "") else {
        print("Error: Unable to determine url from file \(readFile)")
        exit(EXIT_FAILURE)
    }
    do {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        frames = try decoder.decode([Frame].self, from: data)
        var packetCount: Int32 = 0
        for frame in frames {
            packetCount = packetCount + 1
            displayFrame(frame: frame, packetCount: packetCount, arguments: arguments)
        }
        exit(EXIT_SUCCESS)
    } catch {
        print("Unable to decode frames from url \(url) error:\(error)")
        exit(EXIT_FAILURE)
    }
}

//let testfile: String? = "/tmp/a.pcap"
//if let readFile = testfile {
if let readFile = arguments.readFilePcap {
    let url = URL(fileURLWithPath: readFile)
    /*guard let url = Bundle.main.url(forResource: readFile, withExtension: "") else {
        print("Error: Unable to determine url from file \(readFile)")
        exit(EXIT_FAILURE)
    }*/
    do {
        let data = try Data(contentsOf: url)
        switch PcapType.detect(data: data) {
        case .pcap:
            let pcap = try Pcap(data: data)
            for (count,packet) in pcap.packets.enumerated() {
                let frame = Frame(data: packet.packetData, originalLength: packet.originalLength)
                displayFrame(frame: frame, packetCount: Int32(count), arguments: arguments)
            }
        case .pcapng:
            let pcapng = Pcapng(data: data)
            var packetBlocks: [PcapngPacket] = []
            for segment in pcapng?.segments ?? [] {
                packetBlocks.append(contentsOf: segment.packetBlocks)
            }
            for (count,packet) in packetBlocks.enumerated() {
                let frame = Frame(data: packet.packetData, originalLength: packet.originalLength)
                displayFrame(frame: frame, packetCount: Int32(count), arguments: arguments)
            }
        case .neither:
            print("Unable to decode pcap file")
            exit(EXIT_FAILURE)
        }
        exit(EXIT_SUCCESS)
    } catch {
        print("Unable to decode pcap file: \(error)")
        exit(EXIT_FAILURE)
    }
}

let interface = determineInterface(arguments: arguments)

let etherCapture: EtherCapture?
do {
    etherCapture = try EtherCapture(interface: interface, count: arguments.packetCount, command: arguments.expression, snaplen: arguments.snaplen, promiscuous: arguments.promiscuousMode) { frame in
        packetCount = packetCount + 1
        
        displayFrame(frame: frame, packetCount: packetCount, arguments: arguments)
        
        if packetCount == arguments.packetCount {
            finish(success: true)  // does not return
        }
    }
} catch {
    print("\(error)")
    exit(EXIT_FAILURE)
}

RunLoop.current.run()


