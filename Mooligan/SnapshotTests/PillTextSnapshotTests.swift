import DesignComponents
import SnapshotTesting
import SwiftUI
import Testing

/// Starter snapshot coverage. Renders a `DesignComponents` view on the
/// simulator and diffs it against the reference image committed alongside this
/// file under `__Snapshots__/`.
///
/// To refresh the references after an intentional visual change, run the
/// `Mooligan` scheme's tests with `SNAPSHOT_TESTING_RECORD=all` in the
/// environment (or flip `withSnapshotTesting(record: .all)` locally), review
/// the regenerated PNGs, and commit them.
@MainActor
struct PillTextSnapshotTests {
  @Test
  func plainPill() {
    let view = ZStack {
      Color(.systemBackground)
      PillText("Near Mint")
    }
    .frame(width: 200, height: 80)
    .environment(\.colorScheme, .light)

    assertSnapshot(
      of: view,
      as: .image(precision: 0.98, perceptualPrecision: 0.98, layout: .fixed(width: 200, height: 80))
    )
  }
}
