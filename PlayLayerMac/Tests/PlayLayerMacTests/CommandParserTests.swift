import XCTest
@testable import PlayLayerMac

final class CommandParserTests: XCTestCase {
    func testOpenGooglePreset() {
        XCTAssertEqual(CommandParser.parse("open google"), .openPreset(name: "google"))
        XCTAssertEqual(CommandParser.parse("google"), .openPreset(name: "google"))
    }

    func testOpenYouTubePreset() {
        XCTAssertEqual(CommandParser.parse("open youtube"), .openPreset(name: "youtube"))
        XCTAssertEqual(CommandParser.parse("youtube"), .openPreset(name: "youtube"))
    }

    func testYouTubeIntentRouting() {
        XCTAssertEqual(
            CommandParser.parse("yt iron farm tutorial"),
            .youtubeSearch(query: "iron farm tutorial")
        )
        XCTAssertEqual(
            CommandParser.parse("open iron farm tutorial"),
            .youtubeSearch(query: "iron farm tutorial")
        )
    }

    func testImageIntentRouting() {
        XCTAssertEqual(
            CommandParser.parse("game of thrones pictures"),
            .imageSearch(query: "game of thrones")
        )
        XCTAssertEqual(
            CommandParser.parse("show me cyberpunk wallpapers"),
            .imageSearch(query: "cyberpunk wallpapers")
        )
    }

    func testWebSearchRouting() {
        XCTAssertEqual(
            CommandParser.parse("search op amp band pass filter"),
            .webSearch(query: "op amp band pass filter")
        )
        XCTAssertEqual(
            CommandParser.parse("github swift webview example"),
            .webSearch(query: "github swift webview example")
        )
    }

    func testDirectURLRouting() {
        XCTAssertEqual(
            CommandParser.parse("https://example.com"),
            .openURL(URL(string: "https://example.com")!)
        )
    }

    func testEmptyInputIsUnknown() {
        XCTAssertEqual(CommandParser.parse("   "), .unknown)
    }
}
