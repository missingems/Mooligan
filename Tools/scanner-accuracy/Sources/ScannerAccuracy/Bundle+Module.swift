import Foundation

/// The app finds its bundled database through Tuist's generated `Bundle.module`.
/// The tool bundles none, so its first sync downloads the full master instead.
extension Bundle {
  static var module: Bundle { .main }
}
