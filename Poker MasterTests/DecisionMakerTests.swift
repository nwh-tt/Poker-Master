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
    var loadedRanges: [String: [String]] = [:]
    var hero: Player!
    var villian: Player!
    
    override func setUp() {
        hero = Player(position:"BTN", stack: 100.0)
        villian = Player(position:"BB", stack: 100.0)
        loadedRanges = RangesFileManager.loadRanges()
        
    }
    
    func testOpenRaise() {
        hero.position = "BTN"
        hero.hand = [Card(suit: "spade", rank: "K"), Card(suit: "spade", rank: "A")]
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: Player(position: "BB", stack: 100.0), betNumber: 1)
        
        // Assert that the choice is "raise"
        XCTAssertEqual(choice, .raise)
    }
    
    // Test case for open fold on BTN with a weak hand
        func testOpenFold() {
            hero.position = "BTN"
            hero.hand = [Card(suit: "spade", rank: "2"), Card(suit: "heart", rank: "5")] // Weak hand (2-5)
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 1)
            
            // Assert that the choice is "fold" based on weak hand
            XCTAssertEqual(choice, .fold, "Expected to fold with 2-5 on BTN based on open fold ranges.")
        }

        // Test case for bet2 raise scenario
        func test2betRaise() {
            
            hero.position = "BTN"
            hero.hand = [Card(suit: "hearts", rank: "A"), Card(suit: "spades", rank: "A")] // Pocket queens (strong hand)
            villian.position = "UTG"
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 2)
            
            // Assert that the choice is "raise" with a strong hand in the bet2 scenario
            XCTAssertEqual(choice, .raise, "Expected to raise with pocket Aces on BTN in bet2 scenario.")
        }

        // Test case for bet2 fold scenario
        func test2betfold() {
            hero.position = "BTN"
            hero.hand = [Card(suit: "heart", rank: "3"), Card(suit: "spade", rank: "5")] // Weak hand (3-5)
            villian.position = "UTG"
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 2)
            
            // Assert that the choice is "fold" with a weak hand in the bet2 scenario
            XCTAssertEqual(choice, .fold, "Expected to fold with 3-5 on BTN in bet2 scenario.")
        }

        // Test case for bet3 raise scenario
        func test3betRaise() {
            hero.position = "BTN"
            hero.hand = [Card(suit: "diamond", rank: "A"), Card(suit: "club", rank: "K")] // Ace-King suited (strong hand)
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 3)
            
            // Assert that the choice is "raise" with AK suited in the bet3 scenario
            XCTAssertEqual(choice, .raise, "Expected to raise with AK bet3 scenario.")
        }
    
    func test3betCall() {
        hero.position = "SB"
        hero.hand = [Card(suit: "diamond", rank: "A"), Card(suit: "diamond", rank: "J")]
        villian.position = "BB"
        
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 3)
        
        // Assert that the choice is "raise" with AK suited in the bet3 scenario
        XCTAssertEqual(choice, .call, "Expected to Call with AJs")
    }
    
    func test3betFold() {
        hero.position = "SB"
        hero.hand = [Card(suit: "diamond", rank: "2"), Card(suit: "diamond", rank: "J")]
        villian.position = "BB"
        
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 3)
        
        // Assert that the choice is "raise" with AK suited in the bet3 scenario
        XCTAssertEqual(choice, .fold, "Expected to Call with J2s")
    }

        // Test case for bet4 raise scenario
        func test4betRaise() {
            hero.position = "BTN"
            hero.hand = [Card(suit: "heart", rank: "A"), Card(suit: "spade", rank: "A")] // Pocket jacks (strong hand)
            villian.position = "UTG"
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 4)
            
            // Assert that the choice is "raise" with pocket jacks in the bet4 scenario
            XCTAssertEqual(choice, .raise, "Expected to raise with Ace pair 4bet")
        }
    
    func test4betCall() {
        hero.position = "BTN"
        hero.hand = [Card(suit: "heart", rank: "A"), Card(suit: "heart", rank: "Q")] 
        villian.position = "UTG"
        
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 4)
        
        // Assert that the choice is "raise" with pocket jacks in the bet4 scenario
        XCTAssertEqual(choice, .call, "Expected to Call with AQs in bet4 scenario.")
    }
    
    func test4betFold() {
        hero.position = "BTN"
        hero.hand = [Card(suit: "heart", rank: "2"), Card(suit: "spade", rank: "4")]
        villian.position = "UTG"
        
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 4)
        
        // Assert that the choice is "raise" with pocket jacks in the bet4 scenario
        XCTAssertEqual(choice, .fold, "Expected to fold")
    }
    
    

        // Test case for bet5 call scenario
        func test5betCall() {
            hero.position = "BTN"
            hero.hand = [Card(suit: "diamond", rank: "A"), Card(suit: "diamond", rank: "K")]
            villian.position = "BB"
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 5)
            
            // Assert that the choice is "call" with pocket tens in the bet5 scenario
            XCTAssertEqual(choice, .call, "Expected to call with AKs")
        }
    
    func test5betFold() {
        hero.position = "BTN"
        hero.hand = [Card(suit: "diamond", rank: "2"), Card(suit: "diamond", rank: "K")]
        villian.position = "BB"
        
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 5)
        
        // Assert that the choice is "call" with pocket tens in the bet5 scenario
        XCTAssertEqual(choice, .fold, "Expected to fold")
    }

        // Test case for invalid betNumber (fold)
        func testInvalidBetNumber() {
            hero.hand = [Card(suit: "hearts", rank: "10"), Card(suit: "spades", rank: "J")] // Hand that would raise in valid scenarios
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 99) // Invalid bet number
            
            // Assert that the choice is "fold" for invalid bet number
            XCTAssertEqual(choice, .fold, "Expected to fold for invalid bet number.")
        }

        // Test case for missing Villain position (fold)
        func testMissingVillianPosition() {
            hero.hand = [Card(suit: "hearts", rank: "8"), Card(suit: "diamonds", rank: "9")] // Decent hand for BTN
            villian.position = ""  // Villain has no position
            
            let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: villian, betNumber: 2)
            
            // Assert that the choice is "fold" when villain's position is missing
            XCTAssertEqual(choice, .fold, "Expected to fold when Villain position is missing.")
        }
    
    func testNewMakeDecision() {
        let hero = Player(position:"CO", stack: 100.0)
        hero.hand = [Card(suit: "spade", rank: "K"), Card(suit: "spade", rank: "A")]
        let choice = decisionMaker.determineMovePreFlop(hero: hero, villian: Player(position: "BB", stack: 100.0), betNumber: 3)
        print(choice)
        
    }
}
