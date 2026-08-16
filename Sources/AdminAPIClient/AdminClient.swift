import Foundation
import Tracing

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// A banner message as returned by `admin-api`'s `GET /banners`. Only the fields consumers
/// render are decoded - `admin-api`'s `models.BannerMessage` has more (id, scope, timestamps)
/// that no known consumer uses yet.
public struct Banner: Decodable, Sendable, Equatable {
  public let severity: String
  public let message: String
}

/// A maintenance-mode record as returned by `admin-api`'s `GET /maintenance-modes/active`.
public struct MaintenanceMode: Decodable, Sendable, Equatable {
  public let scopeType: String
  public let scopeValue: String
  public let label: String
  public let description: String
  public let startsAt: String
  public let endsAt: String?

  enum CodingKeys: String, CodingKey {
    case scopeType = "scope_type"
    case scopeValue = "scope_value"
    case label
    case description
    case startsAt = "starts_at"
    case endsAt = "ends_at"
  }
}

/// Fetches banner messages and maintenance-mode records from `admin-api` for a set of scopes
/// (e.g. `["platform", "service:catalog"]`), with a bounded-TTL cache and fail-open behavior
/// baked into the client itself - a cross-cutting operational contract every consumer must
/// satisfy identically (see this package's README), not a per-app policy choice. Every fetch
/// method never throws: a disabled client (no base URL), timeout, network error, non-2xx
/// response, or undecodable body all yield an empty array.
public actor AdminClient {
  private let baseURL: URL?
  private let session: URLSession
  private let ttl: TimeInterval

  private var bannerCache: CacheEntry<[Banner]>?
  private var maintenanceCache: CacheEntry<[MaintenanceMode]>?

  private struct CacheEntry<T> {
    let fetchedAt: Date
    let value: T
  }

  /// `baseURL` is `nil` when `admin-api` isn't configured for this environment - the client
  /// is then permanently disabled (every fetch immediately returns an empty array, no
  /// network calls at all).
  public init(baseURL: String?, ttlSeconds: TimeInterval = 90, timeoutSeconds: TimeInterval = 2) {
    self.baseURL = baseURL.flatMap(URL.init(string:))
    self.ttl = ttlSeconds
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = timeoutSeconds
    configuration.timeoutIntervalForResource = timeoutSeconds
    self.session = URLSession(configuration: configuration)
  }

  /// Returns active banners for the given scopes, most-severe-first as returned by
  /// `admin-api`.
  public func fetchBanners(scopes: [String]) async -> [Banner] {
    await withSpan("fetchBanners") { _ in
      if let cached = cached(bannerCache) {
        return cached
      }
      let banners: [Banner] = await getScoped(path: "banners", scopes: scopes)
      bannerCache = CacheEntry(fetchedAt: Date(), value: banners)
      return banners
    }
  }

  /// Returns active maintenance-mode records for the given scopes.
  public func fetchMaintenanceModes(scopes: [String]) async -> [MaintenanceMode] {
    await withSpan("fetchMaintenanceModes") { _ in
      if let cached = cached(maintenanceCache) {
        return cached
      }
      let modes: [MaintenanceMode] = await getScoped(
        path: "maintenance-modes/active", scopes: scopes)
      maintenanceCache = CacheEntry(fetchedAt: Date(), value: modes)
      return modes
    }
  }

  private func cached<T>(_ entry: CacheEntry<T>?) -> T? {
    withSpan("cached") { _ in
      guard let entry, Date().timeIntervalSince(entry.fetchedAt) < ttl else { return nil }
      return entry.value
    }
  }

  private func getScoped<T: Decodable>(path: String, scopes: [String]) async -> [T] {
    await withSpan("getScoped") { _ in
      guard let baseURL else { return [] }
      var components = URLComponents(
        url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
      components?.queryItems = scopes.map { URLQueryItem(name: "scope", value: $0) }
      guard let url = components?.url else { return [] }

      do {
        let (data, response) = try await withCheckedThrowingContinuation {
          (continuation: CheckedContinuation<(Data, URLResponse), Error>) in
          let task = session.dataTask(with: url) { data, response, error in
            if let error {
              continuation.resume(throwing: error)
            } else if let data, let response {
              continuation.resume(returning: (data, response))
            } else {
              continuation.resume(throwing: URLError(.badServerResponse))
            }
          }
          task.resume()
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else {
          return []
        }
        return try JSONDecoder().decode([T].self, from: data)
      } catch {
        return []
      }
    }
  }
}
