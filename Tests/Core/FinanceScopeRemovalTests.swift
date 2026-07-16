import XCTest
@testable import LifePilotCore

/// Guarantees finance/commerce/health/mail-ingestion stay out of Core and scanned sources.
final class FinanceScopeRemovalTests: XCTestCase {
    func testAgentKindExcludesBannedDomains() {
        let raw = Set(AgentKind.allCases.map(\.rawValue))
        for banned in ["finance", "shopping", "health", "email", "bank"] {
            XCTAssertFalse(raw.contains(banned), "Unexpected AgentKind.\(banned)")
        }
    }

    func testDaySignalKindsExcludeFinanceAndHealth() {
        let raw = Set(DaySignal.Kind.allCases.map(\.rawValue))
        XCTAssertFalse(raw.contains("finance"))
        XCTAssertFalse(raw.contains("health"))
    }

    func testActionTypesIncludeExplicitDenials() {
        XCTAssertEqual(
            ActionProposal.ActionType.forbiddenExternalFinancial.rawValue,
            "forbiddenExternalFinancial"
        )
        XCTAssertEqual(ActionProposal.ActionType.forbiddenSendEmail.rawValue, "forbiddenSendEmail")
        XCTAssertFalse(SecurityPolicy().isAllowed(.forbiddenExternalFinancial))
        XCTAssertFalse(SecurityPolicy().isAllowed(.forbiddenSendEmail))
    }

    func testEmailMessageTypeRemovedFromCore() {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let emailModel = root.appendingPathComponent("Core/Models/EmailMessage.swift")
        let mockEmail = root.appendingPathComponent("Mocks/MockEmail.swift")
        XCTAssertFalse(FileManager.default.fileExists(atPath: emailModel.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: mockEmail.path))
    }

    func testArchitectureDiagramOmitsFinanceShoppingHealthKit() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let svgURL = root.appendingPathComponent("Assets/brand/architecture.svg")
        let svg = try String(contentsOf: svgURL, encoding: .utf8)
        XCTAssertFalse(svg.contains(">Finance<"))
        XCTAssertFalse(svg.contains(">Shopping<"))
        XCTAssertFalse(svg.contains("HealthKit"))
        XCTAssertFalse(svg.contains("Spend anomalies"))
    }

    func testOnboardingCopyDoesNotMentionMoneyMovement() throws {
        let root = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let path = root.appendingPathComponent("Features/Onboarding/OnboardingStep.swift")
        let source = try String(contentsOf: path, encoding: .utf8)
        XCTAssertFalse(source.contains("moves money"))
    }
}
