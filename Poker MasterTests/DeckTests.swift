//
//  DeckTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 4/22/24.
//

import XCTest
@testable import Poker_Master

final class DeckTests: XCTestCase {
    let deck = Deck()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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

}
