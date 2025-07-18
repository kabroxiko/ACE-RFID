import XCTest
@testable import ACE_RFID

class FilamentTests: XCTestCase {
    func testFilamentColorHex() {
        let color = Filament.Color(name: "Red", hex: "#FF0000")
        XCTAssertEqual(color.hex, "#FF0000")
    }
    func testFilamentLengthConversion() {
        let filament = Filament(brand: "Test", material: "PLA", color: Filament.Color(name: "Blue", hex: "#0000FF"), length: 330, printTemperature: 200, bedTemperature: 60)
        XCTAssertEqual(filament.convertedWeight, "1kg")
    }
}

class NFCManagerTests: XCTestCase {
    func testNFCManagerInit() {
        let manager = NFCManager()
        XCTAssertNotNil(manager)
    }
}

class FancyAlertTests: XCTestCase {
    func testAlertButtonInit() {
        let button = FancyAlert.AlertButton(title: "Test", action: nil)
        XCTAssertEqual(button.title, "Test")
    }
}
