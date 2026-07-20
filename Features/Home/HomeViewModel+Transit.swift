import Foundation
import LifePilotCore

struct HomeTransitContext {
    var configured = false
    var stopName: String?
    var snapshot: TransitSnapshot?
    var findings: [PlanningFinding] = []
    var note: String?
    var errorMessage: String?
}

extension HomeViewModel {
    func loadTransit(
        preferences: UserPreferences,
        now: Date
    ) async -> HomeTransitContext {
        let stopID = preferences.transitStopID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !stopID.isEmpty else { return HomeTransitContext() }

        do {
            let snapshot = try await integrations.transit.snapshot(
                at: stopID,
                lines: preferences.transitLineNames
            )
            return HomeTransitContext(
                configured: true,
                stopName: preferences.transitStopName.isEmpty ? nil : preferences.transitStopName,
                snapshot: snapshot,
                findings: disruptionFindings(snapshot: snapshot, now: now),
                note: snapshot.isStale ? "Transit cached" : "Transit live",
                errorMessage: snapshot.isStale ? snapshot.errorMessage : nil
            )
        } catch is CancellationError {
            return HomeTransitContext(configured: true)
        } catch {
            return HomeTransitContext(
                configured: true,
                stopName: preferences.transitStopName.isEmpty ? nil : preferences.transitStopName,
                note: "Transit unavailable",
                errorMessage: error.localizedDescription
            )
        }
    }

    func applyTransit(_ context: HomeTransitContext) {
        transitConfigured = context.configured
        transitDepartures = context.snapshot?.departures ?? []
        transitStatuses = context.snapshot?.lineStatuses ?? []
        transitFetchedAt = context.snapshot?.fetchedAt
        transitSource = context.snapshot?.sourceName
        transitStopName = context.stopName
        transitIsStale = context.snapshot?.isStale ?? false
    }

    private func disruptionFindings(
        snapshot: TransitSnapshot,
        now: Date
    ) -> [PlanningFinding] {
        snapshot.disruptions.prefix(3).map { status in
            PlanningFinding(
                kind: .insufficientTravelOrPreparation,
                title: "\(status.lineName) disruption may affect your journey",
                detail: status.statusDescription,
                evidence: [
                    EvidenceItem(
                        summary: "\(status.lineName): \(status.statusDescription)",
                        sourceAgent: .travel,
                        observedAt: snapshot.fetchedAt,
                        freshness: snapshot.isStale ? .stale : .live
                    ),
                ],
                confidence: snapshot.isStale ? 0.65 : 0.9,
                riskLevel: status.severity == .severe ? .medium : .low,
                expiresAt: now.addingTimeInterval(30 * 60),
                suggestedActionSummary: "Allow extra time and check your route before leaving."
            )
        }
    }
}
