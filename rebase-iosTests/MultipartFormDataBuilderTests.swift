import XCTest
@testable import rebase_ios

final class MultipartFormDataBuilderTests: XCTestCase {

    private let boundary = "test-boundary-123"

    func testBuildContainsRequestPart() throws {
        let json = try JSONEncoder().encode(["content": "hello"])
        let builder = MultipartFormDataBuilder(boundary: boundary)
        let body = builder.build(requestJSON: json)
        let bodyString = String(data: body, encoding: .utf8)!

        XCTAssertTrue(bodyString.contains("--\(boundary)\r\n"))
        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"request\""))
        XCTAssertTrue(bodyString.contains("Content-Type: application/json"))
        XCTAssertTrue(bodyString.contains("--\(boundary)--"))
    }

    func testBuildWithImageContainsImagePart() throws {
        let json = try JSONEncoder().encode(["content": "with image"])
        let imageData = Data([0xFF, 0xD8, 0xFF])  // JPEG magic bytes
        let builder = MultipartFormDataBuilder(boundary: boundary)
        let body = builder.build(requestJSON: json, imageData: imageData)
        let bodyString = String(data: body, encoding: .utf8)!

        XCTAssertTrue(bodyString.contains("Content-Disposition: form-data; name=\"image\"; filename=\"upload.jpg\""))
        XCTAssertTrue(bodyString.contains("Content-Type: image/jpeg"))
    }

    func testBuildWithoutImageHasNoImagePart() throws {
        let json = try JSONEncoder().encode(["content": "no image"])
        let builder = MultipartFormDataBuilder(boundary: boundary)
        let body = builder.build(requestJSON: json, imageData: nil)
        let bodyString = String(data: body, encoding: .utf8)!

        XCTAssertFalse(bodyString.contains("name=\"image\""))
    }

    func testContentTypeHeaderContainsBoundary() {
        let builder = MultipartFormDataBuilder(boundary: boundary)
        XCTAssertEqual(builder.contentType, "multipart/form-data; boundary=\(boundary)")
    }

    func testRequestPartPrecedesImagePart() throws {
        let json = try JSONEncoder().encode(["content": "order test"])
        let imageData = Data([0x00])
        let builder = MultipartFormDataBuilder(boundary: boundary)
        let body = builder.build(requestJSON: json, imageData: imageData)
        let bodyString = String(data: body, encoding: .utf8)!

        let requestRange = bodyString.range(of: "name=\"request\"")!
        let imageRange = bodyString.range(of: "name=\"image\"")!
        XCTAssertLessThan(requestRange.lowerBound, imageRange.lowerBound)
    }
}
