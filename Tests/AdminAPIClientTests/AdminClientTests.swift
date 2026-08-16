import XCTest

@testable import AdminAPIClient

final class AdminClientTests: XCTestCase {
  func testDisabledClientReturnsNoBannersWithoutMakingARequest() async {
    let client = AdminClient(baseURL: nil)
    let banners = await client.fetchBanners(scopes: ["platform"])
    XCTAssertTrue(banners.isEmpty)
  }

  func testDisabledClientReturnsNoMaintenanceModesWithoutMakingARequest() async {
    let client = AdminClient(baseURL: nil)
    let modes = await client.fetchMaintenanceModes(scopes: ["platform"])
    XCTAssertTrue(modes.isEmpty)
  }

  func testUnreachableAdminAPIFailsOpenForBanners() async {
    // Port 1 is a reserved/unassigned port that refuses connections immediately on any
    // platform this runs on - exercises the network-error branch without a mock server or
    // a real timeout wait.
    let client = AdminClient(baseURL: "http://127.0.0.1:1")
    let banners = await client.fetchBanners(scopes: ["platform"])
    XCTAssertTrue(banners.isEmpty)
  }

  func testUnreachableAdminAPIFailsOpenForMaintenanceModes() async {
    let client = AdminClient(baseURL: "http://127.0.0.1:1")
    let modes = await client.fetchMaintenanceModes(scopes: ["platform"])
    XCTAssertTrue(modes.isEmpty)
  }

  func testMaintenanceModeDecodesScopeAndDates() throws {
    let json = """
      [{
          "scope_type": "service",
          "scope_value": "catalog",
          "label": "Scheduled downtime",
          "description": "Upgrading the database.",
          "starts_at": "2026-08-01T00:00:00Z",
          "ends_at": "2026-08-01T04:00:00Z"
      }]
      """.data(using: .utf8)!

    let modes = try JSONDecoder().decode([MaintenanceMode].self, from: json)
    XCTAssertEqual(modes.count, 1)
    XCTAssertEqual(modes[0].scopeType, "service")
    XCTAssertEqual(modes[0].scopeValue, "catalog")
    XCTAssertEqual(modes[0].endsAt, "2026-08-01T04:00:00Z")
  }
}
