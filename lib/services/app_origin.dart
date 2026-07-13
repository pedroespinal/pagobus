/// Immutable "birth certificate" of PagoBus.
///
/// This timestamp records the exact moment the app was originally created.
/// It must NEVER be changed by future rebuilds, version bumps, or releases —
/// unlike the version number (which increments every build), this is a fixed
/// historical fact and is intentionally hardcoded rather than derived from
/// build time.
class AppOrigin {
  static final DateTime createdAtUtc = DateTime.utc(2026, 7, 13, 21, 0);
}
