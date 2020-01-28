//
//  ArgumentParser.swift
//  etherdump
//
//  Created by Darrell Root on 1/27/20.
//  Copyright © 2020 com.darrellroot. All rights reserved.
//

import Foundation

class ArgumentParser {
    //This class should be a singleqton
    
    enum ArgumentState {
        case begin
        case etherdump   // the default state when any command can be expected
        case c
        case expression   // near the end of the cli
    }
    var argumentState = ArgumentState.begin
    var expression = ""
    var packetCount: Int32 = 0
    var listAllInterfaces = false
    var displayLinkLayer = false
    
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
                    self.argumentState = .etherdump
                case "-e":
                    self.displayLinkLayer = true
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
                
            }
        }
    }
    func usage() {
        let usageString = """
OVERVIEW: etherdump packet capture tool version 0.0.1
SOURCE: https://github.com/darrellroot/etherdump/
MARKETING: https://networkmom.net/
EMAIL: feedback AT networkmom.net
USAGE: etherdump [options] [expression]

OPTIONS:
  -c <count>              Capture <count> packets and exit
  -D, --list-interfaces   Print list of all interfaces and exit
  -e                      Display link-layer headers
"""
        print(usageString)
    }
    
}
