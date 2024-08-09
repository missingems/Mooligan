import Networking
import SwiftUI

struct FaceView<Card: MagicCard>: View {
  let main: Content<Card>.Description
  let alternate: Content<Card>.Description?
  
  var body: some View {
    if let alternate {
      HStack(alignment: .top) {
        TitleView(
          name: main.name,
          manaCost: main.manaCost
        )
        
        TitleView(
          name: alternate.name,
          manaCost: alternate.manaCost
        )
      }
      
      HStack(alignment: .top) {
        TypelineView(main.typeline)
        TypelineView(alternate.typeline)
      }
      
      HStack(alignment: .top) {
        DescriptionView(main.text)
        DescriptionView(alternate.text)
      }
      
      HStack(alignment: .top) {
        FlavorView(main.flavorText)
        FlavorView(alternate.flavorText)
      }
    }
  }
  
  init?(descriptions: [Content<Card>.Description]) {
    guard Range(1...2).contains(descriptions.count) else {
      return nil
    }
    
    main = descriptions[0]
    alternate = descriptions.last
  }
}
