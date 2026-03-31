//
//  Bill.swift
//  SplitApp
//
//  Created by Valentina Dorina on 31.03.2026.
//

import Foundation

struct Bill {
    let billId: UUID
    let eventId: UUID
    let userPayments: [User: Double]
    let totalAmount: Double
    
    init(eventId: UUID, positions: [Position]) {
        self.billId = UUID()
        self.eventId = eventId
        self.totalAmount = positions.reduce(0) { $0 + $1.amount }
        self.userPayments = [:]
    }
    
   
    
}
