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
        
        Divider()
        
        TitleView(
          name: alternate.name,
          manaCost: alternate.manaCost
        )
      }
      
      Divider()
      
      HStack(alignment: .top) {
        TypelineView(main.typeline)
        Divider()
        TypelineView(alternate.typeline)
      }
      
      Divider()
      
      HStack(alignment: .top) {
        DescriptionView(main.text)
        Divider()
        DescriptionView(alternate.text)
      }
      
      Divider()
      
      HStack(alignment: .top) {
        FlavorView(main.flavorText)
        Divider()
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
