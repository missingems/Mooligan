import Networking
import SwiftUI

struct CardDetailTableView<Card: MagicCard>: View {
  let main: Content<Card>.Description
  let alternate: Content<Card>.Description?
  private let verticalPadding: CGFloat = 8.0
  
  var body: some View {
    HStack(alignment: .top, spacing: 13) {
      TitleView(
        name: main.name,
        manaCost: main.manaCost
      )
      .padding(.vertical, verticalPadding)
      .safeAreaPadding(.leading, nil)
      
      Divider()
      
      TitleView(
        name: alternate?.name,
        manaCost: alternate?.manaCost
      )
      .padding(.vertical, verticalPadding)
      .safeAreaPadding(.trailing, nil)
    }
    
    section(
      isVisible: main.typeline != nil || alternate?.typeline != nil
    ) {
      HStack(alignment: .top, spacing: 8.0) {
        TypelineView(main.typeline)
          .padding(.vertical, verticalPadding)
          .safeAreaPadding(.leading, nil)
        
        Divider()
        
        TypelineView(alternate?.typeline)
          .padding(.vertical, verticalPadding)
          .safeAreaPadding(.trailing, nil)
      }
    }
    
    section(
      isVisible: main.text != nil || alternate?.text != nil
    ) {
      HStack(alignment: .top, spacing: 8.0) {
        DescriptionView(main.text)
          .padding(.vertical, verticalPadding)
          .safeAreaPadding(.leading, nil)
        
        Divider()
        
        DescriptionView(alternate?.text)
          .padding(.vertical, verticalPadding)
          .safeAreaPadding(.trailing, nil)
      }
    }
    
    section(
      isVisible: main.flavorText != nil || alternate?.flavorText != nil
    ) {
      HStack(alignment: .top, spacing: 8.0) {
        FlavorView(main.flavorText)
          .padding(.vertical, verticalPadding)
          .safeAreaPadding(.leading, nil)
        
        Divider()
        
        FlavorView(alternate?.flavorText)
          .padding(.vertical, verticalPadding)
          .safeAreaPadding(.trailing, nil)
      }
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
  
  @ViewBuilder func section(
    isVisible: Bool,
    content: () -> some View
  ) -> some View {
    if isVisible {
      Divider()
        .safeAreaPadding(.leading, nil)
      
      content()
    }
  }
}

#Preview {
  ScrollView {
    VStack(alignment: .leading, spacing: 0) {
      CardDetailTableView(
        descriptions: Content(
          card: MagicCardFixtures.split.value,
          setIconURL: nil,
          faceDirection: .front
        )
        .descriptions
      )
    }
  }
}
