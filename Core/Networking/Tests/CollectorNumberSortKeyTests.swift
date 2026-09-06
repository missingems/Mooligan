@testable import Networking
import Testing

struct CollectorNumberSortKeyTests {
  private func sorted(_ values: [String]) -> [String] {
    values.sorted { CollectorNumber.sortKey($0) < CollectorNumber.sortKey($1) }
  }

  @Test func whenSortingPlainNumbers_shouldOrderNumerically() {
    #expect(sorted(["10", "2", "1", "100", "20"]) == ["1", "2", "10", "20", "100"])
  }

  @Test func whenNumbersHaveLetterSuffixes_shouldGroupByNumberFirst() {
    #expect(sorted(["10b", "2a", "10a", "2b"]) == ["2a", "2b", "10a", "10b"])
  }

  @Test func whenNumbersAreHyphenated_shouldOrderEachSegmentNumerically() {
    #expect(sorted(["2027-10", "2027-2", "2026-9"]) == ["2026-9", "2027-2", "2027-10"])
  }

  @Test func whenNumbersHaveNonASCIIPrefixes_shouldKeepThePrefixSignificant() {
    #expect(sorted(["★10", "★2", "3"]) == ["3", "★2", "★10"])
  }

  @Test func whenPaddingDigits_shouldNotAlterTheStoredCollectorNumber() {
    #expect(CollectorNumber.sortKey("7") == "00000007")
    #expect(CollectorNumber.sortKey("") == "")
  }
}
