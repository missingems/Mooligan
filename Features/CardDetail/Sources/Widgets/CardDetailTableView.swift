import Networking
import SwiftUI

struct CardDetailTableView<Card: MagicCard>: View {
  let main: Content<Card>.Description
  let alternate: Content<Card>.Description?
  let sections: [Section]
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ForEach(sections.indices, id: \.self) { index in
        let isLastIndex = index == sections.count - 1
        let section = sections[index]
        
        Divider().safeAreaPadding(.leading, nil)
        
        HStack(alignment: .top, spacing: 8.0) {
          let edgeInsets = EdgeInsets(
            top: 8,
            leading: 0,
            bottom: isLastIndex ? 13 : 8,
            trailing: 0
          )
          
          switch section.type {
          case .title:
            TitleView(
              name: main.name,
              manaCost: main.manaCost
            )
            .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8.0, trailing: 0))
            
            if let name = alternate?.name, let manaCost = alternate?.manaCost {
              Divider()
              
              TitleView(
                name: name,
                manaCost: manaCost
              )
              .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8, trailing: 0))
            }
            
          case .description:
            if section.title1?.isEmptyOrNil() == false || main.flavorText?.isEmptyOrNil() == false {
              VStack(alignment: .leading, spacing: 8) {
                DescriptionView(section.title1)
                FlavorView(main.flavorText)
              }
              .padding(edgeInsets)
            }
            
            if section.title2?.isEmptyOrNil() == false || alternate?.flavorText?.isEmptyOrNil() == false {
              Divider()
              
              VStack(alignment: .leading, spacing: 8) {
                DescriptionView(section.title2)
                FlavorView(alternate?.flavorText)
              }
              .padding(edgeInsets)
            }
            
          case .typeline:
            TypelineView(section.title1).padding(edgeInsets)
            
            if let title = section.title2 {
              Divider()
              
              TypelineView(title).padding(edgeInsets)
            }
          }
        }
        .safeAreaPadding(.horizontal, nil)
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
        type: .title,
        title1: main.text,
        title2: alternate?.text
      ),
      Section(
        type: .typeline,
        title1: main.typeline,
        title2: alternate?.typeline
      ),
      Section(
        type: .description,
        title1: main.text,
        title2: alternate?.text
      )
    ].compactMap { $0}
  }
}

extension CardDetailTableView {
  struct Section: Identifiable {
    enum SectionType {
      case title
      case description
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
