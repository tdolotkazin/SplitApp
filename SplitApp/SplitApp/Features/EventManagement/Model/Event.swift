//
//  Event.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//


import Foundation

struct Event {
    let id: UUID
    let name: String
    let date: Date
    var positions: [Position]
    var bill: Bill
    
    init(name: String, positions: [Position], bill: Bill) {
        self.id = UUID()
        self.name = name
        self.date = Date()
        self.positions = positions
        self.bill = bill
    }

}
