@testable import Networking
import Testing

struct MatchResultTests {
  @Test(arguments: [
    ("318c363b-61cc-4e2f-8f86-a4287539ea07-face0", 0),
    ("318c363b-61cc-4e2f-8f86-a4287539ea07-face1", 1),
  ])
  func whenTheIDNamesAFace_shouldSplitItIntoCardAndFace(id: String, face: Int) {
    let match = MatchResult(id: id, distance: 0)

    #expect(match.cardID == "318c363b-61cc-4e2f-8f86-a4287539ea07")
    #expect(match.faceIndex == face)
  }

  @Test(arguments: [
    "318c363b-61cc-4e2f-8f86-a4287539ea07",
    // Plain card ids that happen to contain "-face".
    "9f4dee38-face-439a-a815-b6c6aab3ca43",
    "974bf524-0c2d-4b8e-9d3a-face12655874",
    "not-a-card-id-face1",
  ])
  func whenTheIDIsNotAFace_shouldKeepItWhole(id: String) {
    let match = MatchResult(id: id, distance: 0)

    #expect(match.cardID == id)
    #expect(match.faceIndex == nil)
  }
}
