//
//  Log.swift
//  Poker Master
//
//  Created by Ned Whittleton on 12/31/25.
//

import OSLog

enum Log {
    private static let subsystem = "com.nedwhitt.Poker-Master"

    static let app      = Logger(subsystem: subsystem, category: "app")
    static let data = Logger(subsystem: subsystem, category: "data")
    static let ranges   = Logger(subsystem: subsystem, category: "ranges")
    static let auth     = Logger(subsystem: subsystem, category: "auth")
    
    static let aiGame     = Logger(subsystem: subsystem, category: "aiGame")
    static let equityGame     = Logger(subsystem: subsystem, category: "equityGame")
    static let preflopGame     = Logger(subsystem: subsystem, category: "preflopGame")
    static let network  = Logger(subsystem: subsystem, category: "network")
}
