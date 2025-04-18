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
// Extra 1
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

// Extra 2
class GroupPricing: PricingScheme {
    private let keyword1: String
    private let keyword2: String
    private let discount: Double
    
    init(group1: String, group2: String, discount: Double) {
        self.keyword1 = group1.lowercased()
        self.keyword2 = group2.lowercased()
        self.discount = discount
    }
    
    func apply(for items: [any SKU]) -> Int {
        // split into groups
        var group1Items: [SKU] = []
        var group2Items: [SKU] = []
        var normalItems: [SKU] = []
        
        for item in items {
            let name = item.name.lowercased()
            if name.contains(keyword1) {
                group1Items.append(item)
            } else if name.contains(keyword2) {
                group2Items.append(item)
            } else {
                normalItems.append(item)
            }
        }
        
        // count min pair
        let pairCount = min(group1Items.count, group2Items.count)
        
        var total = 0
        
        // calc discount pairs price
        for i in 0..<pairCount {
            let discounted1 = Int(Double(group1Items[i].price()) * (1.0 - discount))
            let discounted2 = Int(Double(group2Items[i].price()) * (1.0 - discount))
            total += discounted1 + discounted2
        }
        
        // add remaining
        for i in pairCount..<group1Items.count {
            total += group1Items[i].price()
        }
        
        for i in pairCount..<group2Items.count {
            total += group2Items[i].price()
        }
        
        for item in normalItems {
            total += item.price()
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
