import Foundation
import ScryfallKit

public extension Card {
  var isTransformable: Bool {
    layout == .transform ||
    layout == .modalDfc ||
    layout == .reversibleCard ||
    layout == .doubleFacedToken
  }
  
  var isFlippable: Bool {
    layout == .flip
  }
  
  var hasMultipleColumns: Bool {
    layout == .split || layout == .adventure
  }
  
  var isPhyrexian: Bool {
    lang == "ph"
  }
  
  var isLandscape: Bool {
    layout == .split || layout == .battle
  }
  
  func manaCost(faceDirection: MagicCardFaceDirection?) -> [String] {
    var manaCost: String?
    
    if let face = getCardFace(for: faceDirection) {
      manaCost = face.manaCost
    } else {
      manaCost = self.manaCost
    }
    
    guard
      let pattern = try? Regex("\\{[^}]+\\}"),
      let manaCost = manaCost?
        .replacingOccurrences(of: "/", with: ":")
        .replacingOccurrences(of: "∞", with: "INFINITY")
    else {
      return []
    }
    
    return manaCost
      .matches(of: pattern)
      .compactMap { String(manaCost[$0.range]) }
  }
  
  func name(faceDirection: MagicCardFaceDirection?) -> String {
    guard let face = getCardFace(for: faceDirection) else {
      return isPhyrexian ? name : printedName ?? name
    }
    
    return isPhyrexian ? face.name : face.printedName ?? face.name
  }
  
  func flavorText(faceDirection: MagicCardFaceDirection?) -> String? {
    guard let face = getCardFace(for: faceDirection) else {
      return flavorText
    }
    
    return face.flavorText
  }
  
  private func getDisplayText(faceDirection: MagicCardFaceDirection?) -> String? {
    var text: String?
    
    if let face = getCardFace(for: faceDirection) {
      text = isPhyrexian ? face.oracleText : face.printedText ?? face.oracleText
    } else {
      text = isPhyrexian ? oracleText : printedText ?? oracleText
    }
    
    guard var text else { return nil }
    
    for keyword in keywords {
      if let regex = try? NSRegularExpression(pattern: "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b", options: [.caseInsensitive]),
         let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..<text.endIndex, in: text)),
         let matchRange = Range(match.range, in: text) {
        text.replaceSubrange(matchRange, with: "<\(text[matchRange])>")
      }
    }
    
    return text
  }
  
  func text(faceDirection: MagicCardFaceDirection?) -> [[TextElement]] {
    return getDisplayText(
      faceDirection: faceDirection
    )?.split(
      separator: "\n"
    ).map {
      TextElementParser.parse(String($0))
    } ?? []
  }
  
  func typeline(faceDirection: MagicCardFaceDirection?) -> String? {
    guard let face = getCardFace(for: faceDirection) else {
      return isPhyrexian ? typeLine : printedTypeLine ?? typeLine
    }
    
    return isPhyrexian ? face.typeLine : face.printedTypeLine ?? face.typeLine
  }
}

extension Card {
  public func getCardFace(for direction: MagicCardFaceDirection?) -> Face? {
    switch direction {
    case .front:
      cardFaces?.first
      
    case .back:
      cardFaces?.last
      
    default:
      nil
    }
  }
  
  public func getGathererURLString() -> String? {
    if let url = relatedUris["gatherer"] {
      url
    } else {
      nil
    }
  }
}
