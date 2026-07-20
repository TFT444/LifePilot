import Foundation
import LifePilotCore
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Live transit provider backed by the free, public **TfL Unified API**
/// (`api.tfl.gov.uk`). This is a Services-layer adapter conforming to the
/// `TransitProviding` protocol defined in `LifePilotCore`, per
/// docs/ARCHITECTURE.md's Dependency Rules and the Travel integration in
/// docs/MASTER_ROADMAP.md Phase 7.
///
/// Anonymous access works (50 req/min); pass a free `appKey` (500 req/min) for
/// production. The network fetch is injectable so decoding/mapping is fully
/// unit-testable without hitting the network.
public struct TfLTransitService: TransitProviding {
    public static let baseURL = "https://api.tfl.gov.uk"

    private let appKey: String?
    private let fetch: @Sendable (URL) async throws -> Data

    /// Production initialiser using `URLSession`.
    public init(
        appKey: String? = nil,
        timeoutInterval: TimeInterval = 8,
        session: URLSession = .shared
    ) {
        self.appKey = appKey
        fetch = { url in
            try await Self.load(
                url,
                timeoutInterval: timeoutInterval,
                session: session
            )
        }
    }

    /// Testing initialiser with an injected fetch (no network).
    public init(appKey: String? = nil, fetch: @escaping @Sendable (URL) async throws -> Data) {
        self.appKey = appKey
        self.fetch = fetch
    }

    public func departures(at stopId: String) async throws -> [TransitDeparture] {
        let data = try await fetch(url(path: "/StopPoint/\(stopId)/Arrivals"))
        return try Self.decodeDepartures(from: data)
    }

    public func lineStatuses() async throws -> [TransitLineStatus] {
        let data = try await fetch(url(path: "/Line/Mode/tube/Status"))
        return try Self.decodeLineStatuses(from: data)
    }

    // MARK: - URL building

    func url(path: String) -> URL {
        let fallback = URL(string: Self.baseURL) ?? URL(fileURLWithPath: "/")
        guard var comps = URLComponents(string: Self.baseURL + path) else {
            return fallback
        }
        if let appKey, !appKey.isEmpty {
            comps.queryItems = [URLQueryItem(name: "app_key", value: appKey)]
        }
        return comps.url ?? fallback
    }

    // MARK: - Networking

    private static func load(
        _ url: URL,
        timeoutInterval: TimeInterval,
        session: URLSession
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeoutInterval
        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        if let http = response as? HTTPURLResponse, !(200 ..< 300).contains(http.statusCode) {
            throw DomainError.unavailableNamed(
                "TfL request failed: HTTP \(http.statusCode)"
            )
        }
        return data
    }

    // MARK: - Decoding (pure, unit-testable)

    static func decodeDepartures(from data: Data) throws -> [TransitDeparture] {
        let dtos = try JSONDecoder().decode([ArrivalDTO].self, from: data)
        return dtos
            .map { dto in
                TransitDeparture(
                    id: dto.id ?? UUID().uuidString,
                    lineName: dto.lineName ?? "",
                    destination: cleanName(dto.destinationName ?? dto.towards ?? "Check front of train"),
                    platform: dto.platformName,
                    secondsToStation: dto.timeToStation ?? 0
                )
            }
            .sorted { $0.secondsToStation < $1.secondsToStation }
    }

    static func decodeLineStatuses(from data: Data) throws -> [TransitLineStatus] {
        let dtos = try JSONDecoder().decode([LineDTO].self, from: data)
        return dtos.map { dto in
            let desc = dto.lineStatuses?.first?.statusSeverityDescription ?? "Unknown"
            return TransitLineStatus(
                lineName: dto.name ?? "",
                statusDescription: desc,
                severity: .classify(desc)
            )
        }
    }

    static func cleanName(_ raw: String) -> String {
        raw.replacingOccurrences(of: " Underground Station", with: "")
            .replacingOccurrences(of: " Rail Station", with: "")
            .replacingOccurrences(of: " DLR Station", with: "")
            .replacingOccurrences(of: " Station", with: "")
    }

    // MARK: - Wire DTOs (match the TfL Unified API response shapes)

    struct ArrivalDTO: Decodable {
        let id: String?
        let lineName: String?
        let destinationName: String?
        let towards: String?
        let platformName: String?
        let timeToStation: Int?
    }

    struct LineDTO: Decodable {
        let name: String?
        let lineStatuses: [LineStatusDTO]?
    }

    struct LineStatusDTO: Decodable {
        let statusSeverityDescription: String?
    }
}
