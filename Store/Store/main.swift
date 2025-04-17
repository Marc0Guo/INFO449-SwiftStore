//
//  main.swift
//  Store
//
//  Created by Ted Neward on 2/29/24.
//

import Foundation

protocol SKU {
    var name : String { get }
    func price() -> Int
}

// Given a list, give me total after applying rule
protocol PricingScheme {
    func apply(for items: [SKU]) -> Int
}

class Item : SKU {
    let name : String
    private let itemPrice: Int
    
    init(name: String, priceEach: Int) {
        self.name = name
        self.itemPrice = priceEach
    }

    func price() -> Int {
        return itemPrice
    }
}

class TwoForOnePricing: PricingScheme {
    func apply(for items: [any SKU]) -> Int {
        var grouped: [String: [SKU]] = [:]
        
        for item in items {
            grouped[item.name, default: []].append(item)
        }
        
        var total = 0
        
        for group in grouped.values {
            let count = group.count
            let price = group.first!.price()
            
            let grouped = count/3 //3->2
            let remain = count % 3
            
            total += (grouped * 2 + remain) * price
        }
        return total
    }
}


class Receipt {
    private var scannedItems: [SKU] = []
    private var pricing: PricingScheme?
    
    init(pricing: PricingScheme? = nil) {
        self.pricing = pricing
    }

    func add(_ item: SKU) {
        scannedItems.append(item)
    }

    func items() -> [SKU] {
        return scannedItems
    }

    func output() -> String {
        var result = "Receipt:\n"
        for item in scannedItems {
            let dollar = Double(item.price()) / 100.0
            result += "\(item.name): $\(String(format: "%.2f", dollar))\n"
        }
        result += "------------------\n"
        let totalAmount = Double(total()) / 100.0
        result += String(format: "TOTAL: $%.2f", totalAmount)
        return result
    }
    
    func total() -> Int {
        if let scheme = pricing {
            return scheme.apply(for: scannedItems)
        } else {
            return scannedItems.reduce(0) { $0 + $1.price() }
        }
    }


    func clear() {
        scannedItems.removeAll()
    }
}

class Register {
    private var currentReceipt = Receipt()
    private var pricing: PricingScheme?
    
    init(pricing: PricingScheme? = nil) {
        self.pricing = pricing
        self.currentReceipt = Receipt(pricing: pricing)
    }

    func scan(_ item: SKU) {
        currentReceipt.add(item)
    }

    func subtotal() -> Int {
        return currentReceipt.total()
    }

    func total() -> Receipt {
        let finishedReceipt = currentReceipt
        currentReceipt = Receipt()
        return finishedReceipt
    }
}

class Store {
    let version = "0.1"
    func helloWorld() -> String {
        return "Hello world"
    }
}
