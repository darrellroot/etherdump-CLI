//
//  ArgumentParser.swift
//  etherdump
//
//  Created by Darrell Root on 1/27/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation
import PackageEtherCapture

class ArgumentParser {
    //This class should be a singleqton
    
    enum ArgumentState {
        case begin
        case etherdump   // the default state when any command can be expected
        case c
        case expression   // near the end of the cli
        case i
        case s
    }
    var argumentState = ArgumentState.begin
    var expression = ""
    var packetCount: Int32 = 0
    var listAllInterfaces = false
    var displayPacketNumber = false
    var displayLinkLayer = false
    var displayTimestamp = true
    var displayHexL2 = false
    var displayHexL3 = false
    var displayVerboseL2 = false
    var displayVerboseL3 = false
    var displayVerboseL4 = false
    var promiscuousMode = true
    var help = false
    var version = false
    var interface: String? = nil
    var snaplen = 96 {
        didSet {
            guard snaplen > 95 else {
                fatalError("Unexpected error: snaplen must be 96 or greater")
            }
        }
    }
    
    init?(_ arguments: [String]) {
        ARGUMENTS: for argument in arguments {
            switch argumentState {
            case .begin:
                self.argumentState = .etherdump
                //continue ARGUMENTS
            case .etherdump:
                switch argument{
                case "-c":
                    self.argumentState = .c
                    //continue ARGUMENTS
                case "-D","--list-interfaces":
                    self.listAllInterfaces = true
                case "-e":
                    self.displayLinkLayer = true
                case "-h","--help":
                    self.help = true
                case "-i":
                    self.argumentState = .i
                case "-#","--number":
                    self.displayPacketNumber = true
                case "-p","--no-promiscuous-mode":
                    self.promiscuousMode = false
                case "-s":
                    self.argumentState = .s
                case "-t":
                    self.displayTimestamp = false
                case "-v2":
                    self.displayVerboseL2 = true
                case "-v3":
                    self.displayVerboseL3 = true
                case "-v4":
                    self.displayVerboseL4 = true
                case "--version":
                    self.version = true
                case "-x":
                    self.displayHexL3 = true
                case "-xx":
                    self.displayHexL2 = true
                default:
                    guard argument.first != "-" else {
                        usage()
                        return nil
                    }
                    self.expression = argument
                    self.argumentState = .expression
                    //continue ARGUMENTS
                }
            case .expression:
                guard argument.first != "-" else {
                    usage()
                    return nil
                }
                self.expression = self.expression + " " + argument
                //continue ARGUMENTS
            case .c:
                guard let packetCount = Int32(argument),packetCount > 0 else {
                    usage()
                    return nil
                }
                self.packetCount = packetCount
                self.argumentState = .etherdump
            case .i:
                self.interface = argument
                self.argumentState = .etherdump
            case .s:
                guard case self.snaplen = Int(argument), self.snaplen >= 96 else {
                    usage()
                    exit(EXIT_FAILURE)
                }
                self.argumentState = .etherdump
            }// switch argumentState
        }// for argument in arguments
        switch argumentState {
            
        case .begin, .etherdump, .expression:  //valid end states
            break
        case .c, .i, .s: // invalid end states
            usage()
            return nil
        }
    }//init?
    func printVersion() {
        let pcapVersion = EtherCapture.pcapVersion()
        print("etherdump packet capture tool version 0.0.1")
        print("\(pcapVersion)")
    }
    func usage() {
        let usageString = """

SOURCE: https://github.com/darrellroot/etherdump/

USAGE: etherdump [options] [expression]

OPTIONS:
  -c <count>              Capture <count> packets and exit
  -D, --list-interfaces   Print list of all interfaces and exit
  -e                      Display link-layer header
  -h, --help              Print this message and exit
  -i <interface>          Listen on <interface>
  -p, --no-promiscuous-mode   Do not put interface into promiscuous-mode
  -#, --number            Print packet number at beginning of line
  -s <snaplen>            Set frame capture size to <snaplen>.  Must be 96 or greater
  -v2                     Display verbose layer-2 information
  -v3                     Display verbose layer-3 information
  -v4                     Display verbose layer-4 information
  --version               Print etherdump and libpcap version and exit
  -x                      Display hexdump starting at layer 3
  -xx                     Display hexdump including layer 2

"""
        printVersion()
        print(usageString)
    }
    
}
