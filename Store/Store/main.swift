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
        // Limitation: grouped discount happen in scanned order.
        //             3 Ketchup 2 bear
        //             the 3rd ketchup won't be discounted no matter price
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

// Extra 3
class WeightItem: SKU {
    let name: String
    private let pricePerPound: Int
    let weight: Double
    
    init(name: String, pricePerPound: Int, weight: Double) {
        self.name = name
        self.pricePerPound = pricePerPound
        self.weight = weight
    }
    
    func price() -> Int {
        return Int(Double(pricePerPound) * weight)
    }
    
    func pricePerUnit() -> Int {
        return pricePerPound
    }
}


// Extra 4
class Coupon: PricingScheme {
    private let keyword1: String
    private let discount: Double
    
    init(item1: String,  discount: Double) {
        self.keyword1 = item1.lowercased()
        self.discount = discount
    }
    
    func apply(for items: [any SKU]) -> Int {
        var matchedItems: [SKU] = []
        var normalItems: [SKU] = []
        
        // split in to groups
        for item in items {
            if item.name.lowercased().contains(keyword1) {
                matchedItems.append(item)
            } else {
                normalItems.append(item)
            }
        }

        // Find the cheapest matched item
        let discountedItem = matchedItems.min(by: { $0.price() < $1.price() })

        var total = 0

        if let itemToDiscount = discountedItem {
            // Apply discount to the cheapest one
            let discountedPrice = Int(Double(itemToDiscount.price()) * (1.0 - discount))
            total += discountedPrice

            // Add the rest of the matched items (without discount)
            for item in matchedItems {
                if ObjectIdentifier(item as AnyObject) != ObjectIdentifier(itemToDiscount as AnyObject) {
                    total += item.price()
                }
            }
        } else {
            // No matches found, skip
        }

        // Add all normal items
        for item in normalItems {
            total += item.price()
        }

        return total
    }
}

// Extra 5
class RainCheck: PricingScheme {
    private let keyword: String
    private let substitutePrice: Int
    private let maxWeight: Double?
    
    init(item: String, substitutePrice: Int, maxWeight: Double? = nil) {
        self.keyword = item.lowercased()
        self.substitutePrice = substitutePrice
        self.maxWeight = maxWeight
    }

    func apply(for items: [SKU]) -> Int {
        var total = 0
        var rainCheckUsed = false

        for item in items {
            let name = item.name.lowercased()
            if !rainCheckUsed && name.contains(keyword) {
                // Weight Item
                if let maxWeight = maxWeight, let weighed = item as? WeightItem {
                    let coveredWeight = min(maxWeight, weighed.weight)
                    let remainingWeight = weighed.weight - coveredWeight

                    let coveredCost = substitutePrice
                    let remainingCost = Int(Double(weighed.pricePerUnit()) * remainingWeight)

                    total += coveredCost + remainingCost
                    rainCheckUsed = true
                }
                // Per-unit item: replace full price
                else {
                    total += substitutePrice
                    rainCheckUsed = true
                }
            } else {
                total += item.price()
            }
        }

        return total
    }

    private func weighedWeight(_ item: WeightItem) -> Double {
        return Mirror(reflecting: item).children.first { $0.label == "weight" }?.value as? Double ?? 0.0
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
