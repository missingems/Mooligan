import Networking
import SwiftUI

struct FaceView<Card: MagicCard>: View {
  enum Error: Swift.Error {
    case impossibleState(reason: String)
  }
  
//  let mainFace: Content<Card>.Description
//  let altFace: Content<Card>.Description?
  
  var body: some View {
    Text("")
  }
  
  init(descriptions: [Content<Card>.Description]) {
    //    let isSplit: Bool
    //
    //    if descriptions.count == 0 {
    //      throw .impossibleState(reason: "Descriptions can't be empty")
    //    } else if descriptions.count > 2 {
    //      isSplit = true
    //      throw .impossibleState(reason: "Descriptions can't be more than 2")
    //    } else {
    //      isSplit = false
    //    }
    //
    //    mainFace = descriptions[0]
    //
    //    if isSplit {
    //      altFace = descriptions.last
    //    } else {
    //      altFace = nil
    //    }
  }
}
