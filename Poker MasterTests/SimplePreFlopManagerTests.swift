//
//  SimplePreFlopManagerTests.swift
//  Poker MasterTests
//
//  Created by Ned Whittleton on 4/13/25.
//

import XCTest

@testable import Poker_Master

final class SimplePreFlopManagerTests: XCTestCase {
    var simpleManager: SimplePreFlopManager!
    var ranges: [String: [String]]!

    override func setUpWithError() throws {
        ranges = RangesFileManager.loadRanges()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testInit() throws {
        // Load in ranges
        
        
        
        // print(simpleManager.loadPossibleRanges())
    }
    
    func testStartGame() async {
        await simpleManager.executeLoop()
    }
    
    func testFailure() {
        simpleManager.betToStopOn = 2
        simpleManager.setUserHand(hero: "SB", villian: "MP")
    }
    
    func testStageTheGame_SetsVillainPosition() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        simpleManager.user?.position = "CO"
        simpleManager.stageTheGame()
        
        let villainPosition = simpleManager.villain?.position
        XCTAssertNotNil(villainPosition, "Villain position should be set.")
    }
    
    func testStageTheGame_SetsUserHand() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        simpleManager.user?.position = "BTN"
        simpleManager.stageTheGame()
        
        let userHand = simpleManager.user?.getHand()
        XCTAssertNotNil(userHand, "User hand should be set.")
        XCTAssertFalse(userHand!.isEmpty, "User hand should not be empty.")
    }
    
    func testStageTheGame_SetsCorrectBetToStopOn() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        simpleManager.user?.position = "MP"
        simpleManager.stageTheGame()

        let stopBet = simpleManager.betToStopOn
        XCTAssertTrue((1...5).contains(stopBet), "betToStopOn should be between 1 and 5.")
    }
    
    func testSetUserHand_Open_DoesNotChangeHand() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        // Given
        simpleManager.betToStopOn = 1
        let originalHand = simpleManager.user?.getHand()
        simpleManager.setUserHand(hero: "CO", villian: "BTN")
        // Then
        XCTAssertEqual(simpleManager.user?.getHand(), originalHand, "Hand should not change when betToStopOn is 2")
    }
    
    func testSetUserHand_VsRaise_DoesNotChangeHand() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        // Given
        simpleManager.betToStopOn = 2
        let originalHand = simpleManager.user?.getHand()
        simpleManager.setUserHand(hero: "CO", villian: "BTN")
        // Then
        XCTAssertEqual(simpleManager.user?.getHand(), originalHand, "Hand should not change when betToStopOn is 2")
    }
    
    func testSetUserHand_VsRaiseMPvCO_DoesNotChangeHand() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        
        // Given
        simpleManager.betToStopOn = 2
        let originalHand = simpleManager.user?.getHand()
        simpleManager.setUserHand(hero: "CO", villian: "MP")
        // Then
        XCTAssertEqual(simpleManager.user?.getHand(), originalHand, "Hand should not change when betToStopOn is 2")
    }
    
    func testSetUserHand_3bet() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        // Given
        simpleManager.betToStopOn = 3
        simpleManager.setUserHand(hero: "CO", villian: "BTN")
        
        let possibleHands = ranges["open_CO_raise"] ?? []
        let userHand = simpleManager.user?.getHand() ?? ""
        
        // Then check if user?.getHand() is in possible hands
        XCTAssertTrue(possibleHands.contains(userHand), "User's hand \(userHand) is not in the expected possible hands.")
    }
    
    func testSetUserHand_4bet() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        // Given
        simpleManager.betToStopOn = 4
        simpleManager.setUserHand(hero: "CO", villian: "MP")
        
        let possibleHands = ranges["bet2_CO_v_MP_raise"] ?? []
        let userHand = simpleManager.user?.getHand() ?? ""
        
        // Then check if user?.getHand() is in possible hands
        XCTAssertTrue(possibleHands.contains(userHand), "User's hand \(userHand) is not in the expected possible hands.")
    }
    
    func testSetUserHand_5bet() {
        simpleManager = SimplePreFlopManager(gameplaySpeed: 5, testingMode: true)
        // Given
        simpleManager.betToStopOn = 5
        simpleManager.setUserHand(hero: "CO", villian: "BTN")
        
        let possibleHands = ranges["bet3_CO_v_BTN_raise"] ?? []
        let userHand = simpleManager.user?.getHand() ?? ""
        
        // Then check if user?.getHand() is in possible hands
        XCTAssertTrue(possibleHands.contains(userHand), "User's hand \(userHand) is not in the expected possible hands.")
    }
    
    
    func testExtractVillainPosition_StandardKey() {
            let key = "bet3_CO_v_BTN_call"
            let result = simpleManager.extractVillainPosition(from: key)
            XCTAssertEqual(result, "BTN")
        }
        
        func testExtractVillainPosition_TwoLetterPosition() {
            let key = "bet2_MP_v_BB_raise"
            let result = simpleManager.extractVillainPosition(from: key)
            XCTAssertEqual(result, "BB")
        }
    
    func testExtractVillainPosition_Open() {
        let key = "open_SB_raise"
        let result = simpleManager.extractVillainPosition(from: key)
        XCTAssertEqual(result, "")
    }


}
