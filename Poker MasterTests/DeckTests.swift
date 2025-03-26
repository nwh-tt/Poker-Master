//
//  DeckTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 4/22/24.
//

import XCTest
@testable import Poker_Master

final class DeckTests: XCTestCase {
    var deck = Deck()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    override func setUp() {
            super.setUp()
            deck = Deck() // Initialize a new deck before each test
        }

        override func tearDown() {
            super.tearDown()
        }

    func testDeckCreates() throws {
        // confirm there are 52 cards in the deck
        XCTAssertEqual(deck.cards.count, 52)
        // confirm there are 13 cards of each suit
        XCTAssertEqual(deck.cards.filter({ $0.suit == "heart" }).count, 13)
        XCTAssertEqual(deck.cards.filter({ $0.suit == "diamond" }).count, 13)
        XCTAssertEqual(deck.cards.filter({ $0.suit == "club" }).count, 13)
        XCTAssertEqual(deck.cards.filter({ $0.suit == "spade" }).count, 13)
    }
    
    func testResetDeckRestoresFullDeck() {
            // Arrange
            _ = deck.dealCard() // Remove a card to simulate a game in progress
            let initialCount = deck.cards.count

            // Act
            deck.resetDeck() // Reset the deck

            // Assert
            XCTAssertEqual(deck.cards.count, 52, "Deck should be reset to 52 cards")
            XCTAssertNotEqual(deck.cards.count, initialCount, "Deck size should change after reset")
        }
    
    func testResetDeckShufflesCards() {
            // Arrange
            let originalOrder = deck.cards // Store initial order of cards

            // Act
            deck.resetDeck() // Reset the deck
            let newOrder = deck.cards // Get the new order after reset

            // Assert
            XCTAssertEqual(newOrder.count, 52, "Deck should contain 52 cards after reset")
            XCTAssertNotEqual(originalOrder, newOrder, "Deck should be shuffled after reset")
        }

}
