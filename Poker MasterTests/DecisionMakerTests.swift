//
//  DecisionMakerTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 6/25/24.
//

import Foundation
import XCTest

@testable import Poker_Master
 
final class DecisionMakerTests: XCTestCase {
    let decisionMaker = DecisionMaker()
    
    func testMakeDecision() {
        let hero = Player(position:"BTN", stack: 100.0)
        hero.hand = [Card(suit: "spade", rank: "K"), Card(suit: "spade", rank: "A")]
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: Player(position: "UTG", stack: 100.0), betNumber: 2)
        print(choice)
    }
    
}
