import Foundation
import XCTest

@testable import GildedRose

/**
 * A reminder of the business logic:
 *
 *   - All items have a SellIn value which denotes the number of days we have to sell the item
 *   - All items have a Quality value which denotes how valuable the item is
 *   - At the end of each day our system lowers both values for every item
 *
 *   - Once the sell by date has passed, Quality degrades twice as fast ✅
 *   - The Quality of an item is never negative ✅
 *   - "Aged Brie" actually increases in Quality the older it gets ✅
 *   - The Quality of an item is never more than 50
 *   - "Sulfuras", being a legendary item, never has to be sold or decreases in Quality ✅
 *   - "Backstage passes", like aged brie, increases in Quality as its SellIn value approaches;
 *   - Quality increases by 2 when there are 10 days or less and by 3 when there are 5 days or less but ✅
 *   - Quality drops to 0 after the concert ✅
 */
class GildedRoseTests: XCTestCase {

    var items: [Item] = []
    var app: GildedRose!
    
    override func setUp() {}
    
    func setupManyItems() {
        items = [
            Item(name: "+5 Dexterity Vest", sellIn: 10, quality: 20),
            Item(name: "Aged Brie", sellIn: 2, quality: 0),
            Item(name: "Elixir of the Mongoose", sellIn: 5, quality: 7),
            Item(name: "Sulfuras, Hand of Ragnaros", sellIn: 0, quality: 80),
            Item(name: "Sulfuras, Hand of Ragnaros", sellIn: -1, quality: 80),
            Item(name: "Backstage passes to a TAFKAL80ETC concert", sellIn: 15, quality: 20),
            Item(name: "Backstage passes to a TAFKAL80ETC concert", sellIn: 10, quality: 49),
            Item(name: "Backstage passes to a TAFKAL80ETC concert", sellIn: 5, quality: 49),
            // this conjured item does not work properly yet
            Item(name: "Conjured Mana Cake", sellIn: 3, quality: 6)
        ]
        app = GildedRose(items: items)
    }
    
    func setupOneItem() {
        items = [
            Item(name: "foo", sellIn: 5, quality: 20),
        ]
        app = GildedRose(items: items)
    }
    
    func testSellInDecreasesBy1() throws {
        setupManyItems()
        
        app.updateQuality()
        XCTAssertEqual(items[1].sellIn, 1)
        
        XCTAssertEqual(items[3].sellIn, 0) // Sulfuras should not change
        XCTAssertEqual(items[4].sellIn, -1)
        
        app.updateQuality();
        XCTAssertEqual(items[1].sellIn, 0)
        
        app.updateQuality();
        XCTAssertEqual(items[1].sellIn, -1)
        
        app.updateQuality();
        XCTAssertEqual(items[1].sellIn, -2)
        XCTAssertEqual(items[2].sellIn, 1)

        XCTAssertEqual(items[3].sellIn, 0) // Sulfuras should not change
        XCTAssertEqual(items[4].sellIn, -1)
    }
    
    func testQualityIsNeverNegative() {
        let expectedQuality = [
            19, 18, 17, 16, 15,
            13 /* double decrease */, 11, 9, 7, 5, 3, 1,
            0 /* never negative */, 0, 0]
        
        let days = 15
        for i in 0..<days {
            app.updateQuality();
            print(items[0])
            XCTAssertEqual(items[1].quality, expectedQuality[i])
        }
    }
    
    func testBrieQualityIncreases() {
        setupManyItems()
        let expectedQuality = [
            1, 2,
            4, 6, 8, /* doubles after sellby date */
            10, 12, 14, 16, 18,
            20, 22, 24, 26, 28,
            30, 32, 34, 36, 38,
            40, 42, 44, 46, 48,
            50, 50, 50 /* max out at 50 */
        ]
        
        let days = 28
        for i in 0..<days {
            app.updateQuality();
            print(items[1])
            XCTAssertEqual(items[1].quality, expectedQuality[i])
        }
    }
    
    /**
     * Assumption: "After the concert" is sellIn < 0
     */
    func testBackstagePassesQualityIncreasesAndDropsToZero() {
        setupManyItems()
        
        let days = 18
        for i in 0..<days {
            app.updateQuality();
            print(i, items[5], items[6], items[7])
            
            if i == 4 {
                XCTAssertEqual(items[7].quality, 50)
                XCTAssertEqual(items[5].quality, 25)
            }
            
            if i == 5 {
                XCTAssertEqual(items[7].quality, 0) // Drops to 0
                XCTAssertEqual(items[5].quality, 27) // Increases by 2
            }
            
            // Increases by 3 if SellIn <= 5
            if i == 13 {
                XCTAssertEqual(items[5].quality, 47) // Drops to 0
            }

            if i == 14 {
                XCTAssertEqual(items[5].quality, 50) // Increases by 3
            }

            
            // Stays at zero
            if i == 17 {
                XCTAssertEqual(items[7].quality, 0) // Drops to 0
                XCTAssertEqual(items[5].quality, 0) // Drops to 0
            }
            
            

        }
    }
    
    /**
     * Sulfuras values should not change
     */
    func testSulfurasDoesntChange() throws {
        setupManyItems()
        
        let days = 50
        for i in 0..<days {
            XCTAssertEqual(items[3].quality, 80) // Drops to 0
            XCTAssertEqual(items[3].sellIn, 0) // Drops to 0
            XCTAssertEqual(items[4].quality, 80) // Drops to 0
            XCTAssertEqual(items[4].sellIn, -1) // Drops to 0
        }
        
    }
}
