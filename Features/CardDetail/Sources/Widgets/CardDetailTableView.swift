import Networking
import SwiftUI

struct CardDetailTableView<Card: MagicCard>: View {
  let main: Content<Card>.Description
  let alternate: Content<Card>.Description?
  
  var body: some View {
    HStack(alignment: .top) {
      TitleView(
        name: main.name,
        manaCost: main.manaCost
      )
      
      Divider()
      
      TitleView(
        name: alternate?.name,
        manaCost: alternate?.manaCost
      )
    }
    
    Divider()
    
    HStack(alignment: .top) {
      TypelineView(main.typeline)
      Divider()
      TypelineView(alternate?.typeline)
    }
    
    Divider()
    
    HStack(alignment: .top) {
      DescriptionView(main.text)
      Divider()
      DescriptionView(alternate?.text)
    }
    
    Divider()
    
    HStack(alignment: .top) {
      FlavorView(main.flavorText)
      Divider()
      FlavorView(alternate?.flavorText)
    }
  }
  
  init?(descriptions: [Content<Card>.Description]) {
    if descriptions.count == 1, let main = descriptions.first {
      self.main = main
      self.alternate = nil
    } else if descriptions.count == 2, let main = descriptions.first, let alternate = descriptions.last {
      self.main = main
      self.alternate = alternate
    } else {
      return nil
    }
  }
}
