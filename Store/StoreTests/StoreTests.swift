//
//  StoreTests.swift
//  StoreTests
//
//  Created by Ted Neward on 2/29/24.
//

import XCTest

final class StoreTests: XCTestCase {

    var register = Register()

    override func setUpWithError() throws {
        register = Register()
    }

    override func tearDownWithError() throws { }

    func testBaseline() throws {
        XCTAssertEqual("0.1", Store().version)
        XCTAssertEqual("Hello world", Store().helloWorld())
    }
    
    func testOneItem() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(199, receipt.total())

        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
------------------
TOTAL: $1.99
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    func testThreeSameItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199 * 3, register.subtotal())
    }
    
    func testThreeDifferentItems() {
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        XCTAssertEqual(199, register.subtotal())
        register.scan(Item(name: "Pencil", priceEach: 99))
        XCTAssertEqual(298, register.subtotal())
        register.scan(Item(name: "Granols Bars (Box, 8ct)", priceEach: 499))
        XCTAssertEqual(797, register.subtotal())
        
        let receipt = register.total()
        XCTAssertEqual(797, receipt.total())

        let expectedReceipt = """
Receipt:
Beans (8oz Can): $1.99
Pencil: $0.99
Granols Bars (Box, 8ct): $4.99
------------------
TOTAL: $7.97
"""
        XCTAssertEqual(expectedReceipt, receipt.output())
    }
    
    // Test TwoForOne
    func testTwoForOneThreeItems() {
        register = Register(pricing: TwoForOnePricing())
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        
        let receipt = register.total()
        XCTAssertEqual(199 * 2, receipt.total())
    }
    
    func testTwoForOneTwoItems() {
        register = Register(pricing: TwoForOnePricing())
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Pencil", priceEach: 99))
        register.scan(Item(name: "Pencil", priceEach: 99))
        
        let receipt = register.total()
        XCTAssertEqual(199 * 2 + 99 * 2, receipt.total())
    }
    
    func testTwoForOneFourItems() {
        register = Register(pricing: TwoForOnePricing())
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        
        let receipt = register.total()
        XCTAssertEqual(199 * 3, receipt.total())
    }
    
    // Test grouping
    func testGroupedPricingBasic() {
        let pricing = GroupPricing(group1: "ketchup", group2: "beer", discount: 0.10)

        register = Register(pricing: pricing)

        register.scan(Item(name: "A Ketchup", priceEach: 300))
        register.scan(Item(name: "A Beer", priceEach: 500))
        register.scan(Item(name: "B Ketchup", priceEach: 300))
        register.scan(Item(name: "B Beer", priceEach: 500))

        let receipt = register.total()
        let expectedTotal = Int(Double(300) * 0.9) * 2 + Int(Double(500) * 0.9) * 2
        XCTAssertEqual(expectedTotal, receipt.total())
    }
    
    func testGroupedPricingExtraKetchup() {
        let pricing = GroupPricing(group1: "ketchup", group2: "beer", discount: 0.10)

        register = Register(pricing: pricing)

        register.scan(Item(name: "A Ketchup", priceEach: 300))
        register.scan(Item(name: "A Beer", priceEach: 500))
        register.scan(Item(name: "A Ketchup", priceEach: 300))
        register.scan(Item(name: "B Beer", priceEach: 500))
        register.scan(Item(name: "C Ketchup", priceEach: 300))

        let discountedKetchups = Int(Double(300) * 0.9) * 2
        let discountedBeers = Int(Double(500) * 0.9) * 2
        let fullPriceKetchup = 300
        let expectedTotal = discountedKetchups + discountedBeers + fullPriceKetchup
        let receipt = register.total()
        XCTAssertEqual(expectedTotal, receipt.total())
    }
    
    func testGroupedPricingOnlyKetchup() {
        let pricing = GroupPricing(group1: "ketchup", group2: "beer", discount: 0.10)

        register = Register(pricing: pricing)

        register.scan(Item(name: "A Ketchup", priceEach: 300))
        register.scan(Item(name: "B Ketchup", priceEach: 300))
        register.scan(Item(name: "Pencil", priceEach: 100))

        let expectedTotal = 300 + 300 + 100
        let receipt = register.total()
        XCTAssertEqual(expectedTotal, receipt.total())
    }
    
    // Coupon test
    func testCouponOneBean() {
        let coupon = Coupon(item1: "beans", discount: 0.15)
        register = Register(pricing: coupon)
        
        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        
        let receipt = register.total()
        let expectedTotal = Int(Double(199) * 0.85)
        XCTAssertEqual(expectedTotal, receipt.total())
    }
    
    func testCouponTwoBeansDifferentPrices() {
        let coupon = Coupon(item1: "beans", discount: 0.15)
        register = Register(pricing: coupon)

        register.scan(Item(name: "Beans (8oz Can)", priceEach: 199))
        register.scan(Item(name: "Beans (16oz Can)", priceEach: 299))

        let expectedTotal = Int(Double(199) * 0.85) + 299
        let receipt = register.total()
        XCTAssertEqual(expectedTotal, receipt.total())
    }
    
    func testCouponNoBeans() {
        let coupon = Coupon(item1: "beans", discount: 0.15)
        register = Register(pricing: coupon)

        register.scan(Item(name: "Apple", priceEach: 100))
        register.scan(Item(name: "Banana", priceEach: 150))

        let expectedTotal = 100 + 150
        let receipt = register.total()
        XCTAssertEqual(expectedTotal, receipt.total())
    }
    
}
