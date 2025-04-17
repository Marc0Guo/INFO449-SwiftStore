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

class Receipt {
    private var scannedItems: [SKU] = []

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
        return scannedItems.reduce(0) { $0 + $1.price() }
    }


    func clear() {
        scannedItems.removeAll()
    }
}

class Register {
    private var currentReceipt = Receipt()

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

