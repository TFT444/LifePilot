import Foundation

/// Schema version tracking for LifePilot-owned persistence (#34).
public enum PersistenceSchema {
    public static let currentVersion = 1
}

/// A single additive migration step. Real SwiftData migrations call into
/// this same ordered list so tests can prove upgrades without Xcode-only APIs.
public struct PersistenceMigration: Sendable, Equatable {
    public let fromVersion: Int
    public let toVersion: Int
    public let identifier: String

    public init(fromVersion: Int, toVersion: Int, identifier: String) {
        self.fromVersion = fromVersion
        self.toVersion = toVersion
        self.identifier = identifier
    }
}

/// Applies ordered migrations from a stored schema version to current.
public struct PersistenceMigrator: Sendable {
    public let migrations: [PersistenceMigration]

    public init(migrations: [PersistenceMigration] = PersistenceMigrator.defaultMigrations) {
        self.migrations = migrations
    }

    public static let defaultMigrations: [PersistenceMigration] = [
        PersistenceMigration(
            fromVersion: 0,
            toVersion: 1,
            identifier: "v0_to_v1_baseline_daily_life"
        ),
    ]

    /// Returns the migrations that must run to move `from` toward current.
    public func plan(from storedVersion: Int) throws -> [PersistenceMigration] {
        guard storedVersion <= PersistenceSchema.currentVersion else {
            throw DomainError.invalidState(
                "Stored schema \(storedVersion) is newer than "
                    + "\(PersistenceSchema.currentVersion)"
            )
        }
        return migrations.filter {
            $0.fromVersion >= storedVersion && $0.toVersion <= PersistenceSchema.currentVersion
        }
    }

    public func migrate(from storedVersion: Int) throws -> Int {
        let steps = try plan(from: storedVersion)
        var version = storedVersion
        for step in steps {
            guard step.fromVersion == version else {
                throw DomainError.invalidState(
                    "Migration ordering broken at \(step.identifier)"
                )
            }
            version = step.toVersion
        }
        return version
    }
}

/// Lightweight metadata document stored beside LifePilot data.
public struct PersistenceManifest: Codable, Sendable, Equatable {
    public var schemaVersion: Int
    public var lastMigratedAt: Date?

    public init(schemaVersion: Int = 0, lastMigratedAt: Date? = nil) {
        self.schemaVersion = schemaVersion
        self.lastMigratedAt = lastMigratedAt
    }
}
