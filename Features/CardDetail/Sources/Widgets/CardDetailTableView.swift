import Networking
import SwiftUI

struct CardDetailTableView<Card: MagicCard>: View {
  let main: Content<Card>.Description
  let alternate: Content<Card>.Description?
  let sections: [Section]
  
  var body: some View {
    Divider()
    
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top, spacing: 8.0) {
        TitleView(
          name: main.name,
          manaCost: main.manaCost
        )
        .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8.0, trailing: 0))
        .safeAreaPadding(.leading, nil)
        
        Divider()
        
        TitleView(
          name: alternate?.name,
          manaCost: alternate?.manaCost
        )
        .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 5, trailing: 0))
        .safeAreaPadding(.trailing, nil)
      }
      
      ForEach(sections.indices, id: \.self) { index in
        let isLastIndex = index == sections.count - 1
        let section = sections[index]
        
        Divider().safeAreaPadding(.leading, nil)
        
        HStack(alignment: .top, spacing: 8.0) {
          let edgeInsets = EdgeInsets(
            top: 5,
            leading: 0,
            bottom: isLastIndex ? 13 : 5,
            trailing: 0
          )
          
          switch section.type {
          case .title:
            DescriptionView(main.text)
              .padding(edgeInsets)
              .safeAreaPadding(.leading, nil)
            
            Divider()
            
            DescriptionView(alternate?.text)
              .padding(edgeInsets)
              .safeAreaPadding(.trailing, nil)
            
          case .typeline:
            TypelineView(main.typeline)
              .padding(edgeInsets)
              .safeAreaPadding(.leading, nil)
            
            Divider()
            
            TypelineView(alternate?.typeline)
              .padding(edgeInsets)
              .safeAreaPadding(.trailing, nil)
            
          case .flavor:
            FlavorView(section.title1)
              .padding(edgeInsets)
              .safeAreaPadding(.leading, nil)
            
            Divider()
            
            FlavorView(section.title2)
              .padding(edgeInsets)
              .safeAreaPadding(.trailing, nil)
          }
        }
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
    
    sections = [
      Section(
        type: .typeline,
        title1: main.typeline,
        title2: alternate?.typeline
      ),
      Section(
        type: .title,
        title1: main.text,
        title2: alternate?.text
      ),
      Section(
        type: .flavor,
        title1: main.flavorText,
        title2: alternate?.flavorText
      )
    ].compactMap { $0}
  }
}

extension CardDetailTableView {
  struct Section: Identifiable {
    enum SectionType {
      case flavor
      case title
      case typeline
    }
    
    let id = UUID()
    let type: SectionType
    let title1: String?
    let title2: String?
    
    init?(
      type: SectionType,
      title1: String?,
      title2: String?
    ) {
      if title1?.isEmptyOrNil() == false || title2?.isEmptyOrNil() == false {
        self.title1 = title1
        self.title2 = title2
        self.type = type
      } else {
        return nil
      }
    }
  }
}

fileprivate extension String {
  func isEmptyOrNil() -> Bool {
    isEmpty || trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
