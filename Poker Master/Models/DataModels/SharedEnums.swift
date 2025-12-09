//
//  Models.swift
//  Poker Master
//
//  Created by Ned Whittleton on 8/23/25.
//

import Foundation


enum Position: String, Codable, CaseIterable {
    case utg, utg1, utg2, mp, mp1, mp2, co, btn, sb, bb
}

enum Action: String, Codable, CaseIterable {
    case fold, call, raise, check, none
}
