/// Marker type for the `LifePilotServices` module. This layer is
/// intentionally empty in Phase 3 — per this phase's explicit scope,
/// no APIs, EventKit, WeatherKit, HealthKit, CloudKit, or Supabase
/// integrations are implemented yet. Real service adapters arrive in
/// docs/MASTER_ROADMAP.md Phase 7, each conforming to a protocol defined
/// in `LifePilotCore`, per docs/ARCHITECTURE.md's Dependency Rules.
public enum ServiceModule {}
