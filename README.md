# admin-api-client.swift

[![Coverage](https://img.shields.io/endpoint?url=https://sweetrpg.github.io/admin-api-client.swift/coverage-badge.json)](https://sweetrpg.github.io/admin-api-client.swift/)

Swift client SDK for `admin-api`: fetches active banner messages and maintenance-mode records.

## Scope

`AdminClient` exposes two methods, `fetchBanners(scopes:)` and
`fetchMaintenanceModes(scopes:)`. Unlike a domain API client SDK (e.g. `catalog-api-client.swift`),
caching, request timeout (2s), and fail-open behavior are baked into this package rather than
left to the consumer - every frontend must behave identically for this cross-cutting concern.
Both methods cache their own result for 90 seconds and never throw: a disabled client (no base
URL), timeout, network error, non-2xx response, or undecodable body all yield an empty array.

## Usage

```swift
import AdminAPIClient

let client = AdminClient(baseURL: ProcessInfo.processInfo.environment["ADMIN_API_URL"])
let banners = await client.fetchBanners(scopes: ["platform", "service:catalog"])
let maintenanceModes = await client.fetchMaintenanceModes(scopes: ["platform", "service:catalog"])
```
