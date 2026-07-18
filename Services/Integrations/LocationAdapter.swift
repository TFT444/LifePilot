import Foundation
import LifePilotCore

#if canImport(CoreLocation)
import CoreLocation
#endif

#if canImport(CoreLocation)
/// CoreLocation When-In-Use adapter. Request only from Settings / Home weather path.
public final class CoreLocationProvider: NSObject, LocationProviding, CLLocationManagerDelegate, @unchecked Sendable {
    private let manager = CLLocationManager()
    private let lock = NSLock()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    public override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    public func authorizationState() async -> CapabilityState {
        switch manager.authorizationStatus {
        case .notDetermined: return .notDetermined
        case .restricted, .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        @unknown default: return .notDetermined
        }
    }

    public func requestAuthorization() async -> CapabilityState {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try? await Task.sleep(for: .milliseconds(500))
        }
        return await authorizationState()
    }

    public func currentCoordinate() async throws -> GeoCoordinate {
        let status = manager.authorizationStatus
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            throw DomainError.unauthorized
        }
        let location: CLLocation = try await withCheckedThrowingContinuation { cont in
            lock.lock()
            if continuation != nil {
                lock.unlock()
                cont.resume(throwing: DomainError.conflict)
                return
            }
            continuation = cont
            lock.unlock()
            manager.requestLocation()
        }
        return GeoCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
    }

    public func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        if let cont {
            if let location = locations.first {
                cont.resume(returning: location)
            } else {
                cont.resume(throwing: DomainError.unavailableNamed("No location reading"))
            }
        }
    }

    public func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        lock.lock()
        let cont = continuation
        continuation = nil
        lock.unlock()
        cont?.resume(throwing: error)
    }
}
#endif

/// Production location provider: CoreLocation when available, else unavailable.
public struct SystemLocationProvider: LocationProviding {
    #if canImport(CoreLocation)
    private let inner: CoreLocationProvider

    public init() {
        inner = CoreLocationProvider()
    }

    public func authorizationState() async -> CapabilityState {
        await inner.authorizationState()
    }

    public func requestAuthorization() async -> CapabilityState {
        await inner.requestAuthorization()
    }

    public func currentCoordinate() async throws -> GeoCoordinate {
        try await inner.currentCoordinate()
    }
    #else
    public init() {}

    public func authorizationState() async -> CapabilityState {
        .unavailable
    }

    public func requestAuthorization() async -> CapabilityState {
        .unavailable
    }

    public func currentCoordinate() async throws -> GeoCoordinate {
        throw DomainError.unavailableNamed("CoreLocation unavailable")
    }
    #endif
}
