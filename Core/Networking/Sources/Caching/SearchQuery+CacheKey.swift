import Foundation

extension SearchQuery {
  var cacheKey: String {
    let types = cardType.map(\.rawValue).sorted().joined(separator: ",")
    let colors = colorIdentities.map(\.rawValue).sorted().joined(separator: ",")

    return [
      "n=\(name)",
      "s=\(setCode ?? "")",
      "cn=\(collectorNumber ?? "")",
      "o=\(oracleID ?? "")",
      "t=\(types)",
      "ci=\(colors)",
      "sort=\(sortMode.rawValue)",
      "dir=\(sortDirection.rawValue)",
    ]
    .joined(separator: "|")
  }

  var isUnfilteredSetBrowse: Bool {
    setCode != nil
      && name.isEmpty
      && collectorNumber == nil
      && oracleID == nil
      && colorIdentities.isEmpty
      && (cardType.isEmpty || cardType == [.all])
  }
}
