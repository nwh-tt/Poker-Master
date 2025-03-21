//
//  User.swift
//  Poker Master
//
//  Created by Ned Whittleton on 3/21/25.
//

import Foundation


class User: Player {
    var playerMove: LastMove
    
    init(playerMove: LastMove) {
        self.playerMove = playerMove
        super.init(position: "User", stack: 1000.0)
    }
}
