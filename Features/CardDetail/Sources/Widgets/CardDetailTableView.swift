import Networking
import SwiftUI

struct CardDetailTableView<Card: MagicCard>: View {
  let sections: [SectionType]
  
  var body: some View {
    VStack(spacing: 0) {
      ForEach(sections.indices, id: \.self) { index in
        Divider().safeAreaPadding(.leading, nil)
        
        let section = sections[index]
        let isLast = index == sections.count - 1
        
        let edgeInsets = EdgeInsets(
          top: 8,
          leading: 0,
          bottom: isLast ? 13 : 8,
          trailing: 0
        )
        
        switch section {
        case let .title(name1, manaCost1):
          TitleView(
            name: name1,
            manaCost: manaCost1
          )
          .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8.0, trailing: 0))
          .safeAreaPadding(.horizontal, nil)
          
        case let .titles(name1, manaCost1, name2, manaCost2):
          HStack(alignment: .top, spacing: 8.0) {
            TitleView(
              name: name1,
              manaCost: manaCost1
            )
            .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8.0, trailing: 0))
            
            if let name2, let manaCost2 {
              Divider()
              
              TitleView(
                name: name2,
                manaCost: manaCost2
              )
              .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8, trailing: 0))
            }
          }
          .safeAreaPadding(.horizontal, nil)
          
        case let .typeline(value):
          TypelineView(value)
            .padding(edgeInsets)
            .safeAreaPadding(.horizontal, nil)
          
        case let .typelines(text1, text2):
          HStack(alignment: .top, spacing: 8.0) {
            TypelineView(text1).padding(edgeInsets)
            
            if let text2 {
              Divider()
              
              TypelineView(text2).padding(edgeInsets)
            }
          }
          .safeAreaPadding(.horizontal, nil)
          
        case let .description(text, flavor, keywords):
          if text.isEmpty == false || flavor?.isEmptyOrNil() == false {
            VStack(alignment: .leading, spacing: 8) {
              DescriptionView(text, keywords: keywords)
              FlavorView(flavor)
            }
            .padding(edgeInsets)
            .safeAreaPadding(.horizontal, nil)
          }
          
        case let .descriptions(text1, flavor1, text2, flavor2, keywords):
          HStack(alignment: .top, spacing: 8.0) {
            if text1.isEmpty == false || flavor1?.isEmptyOrNil() == false {
              VStack(alignment: .leading, spacing: 8) {
                DescriptionView(text1, keywords: keywords)
                  .frame(maxWidth: .infinity)
                FlavorView(flavor1)
              }
              .padding(edgeInsets)
            }
            
            if text2.isEmpty == false || flavor2?.isEmptyOrNil() == false {
              Divider()
              
              VStack(alignment: .leading, spacing: 8) {
                DescriptionView(text2, keywords: keywords)
                  .frame(maxWidth: .infinity)
                FlavorView(flavor2)
              }
              .padding(edgeInsets)
            }
          }
          .safeAreaPadding(.horizontal, nil)
        }
      }
    }
  }
  
  init?(descriptions: [Content<Card>.Description], keywords: [String]) {
    if descriptions.count == 1, let main = descriptions.first {
      self.sections = [
          .title(main.name, main.manaCost),
          .typeline(main.typeline),
          .description(main.textElements, main.flavorText, keywords),
      ]
    } else if descriptions.count == 2, let main = descriptions.first, let alternate = descriptions.last {
      self.sections = [
        .titles(title1: main.name, manaCost1: main.manaCost, title2: alternate.name, manaCost2: alternate.manaCost),
        .typelines(typeline1: main.typeline, typeline2: alternate.typeline),
        .descriptions(description1: main.textElements, flavorText1: main.flavorText, description2: alternate.textElements, flavorText2: alternate.flavorText, keywords: keywords),
      ]
    } else {
      return nil
    }
  }
}

extension CardDetailTableView {
  enum SectionType: Identifiable, Hashable {
    case titles(title1: String, manaCost1: [String], title2: String?, manaCost2: [String]?)
    case title(String, [String])
    case descriptions(description1: [[TextElement]], flavorText1: String?, description2: [[TextElement]], flavorText2: String?, keywords: [String])
    case description([[TextElement]], String?, [String])
    case typelines(typeline1: String?, typeline2: String?)
    case typeline(String?)
    
    nonisolated(unsafe) var id: Self {
      return self
    }
  }
}

fileprivate extension String {
  func isEmptyOrNil() -> Bool {
    isEmpty || trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
