import Networking
import SwiftUI

struct CardDetailTableView<Card: MagicCard>: View {
  let arrangement: Arrangement
  
  var body: some View {
    switch arrangement {
    case let .horizontal(mainColumn, alternativeColumn):
      Text("")
    case let .vertical(sections):
      Text("")
    }
//    VStack(spacing: 0) {
//      HStack {
//        ForEach(sections.indices, id: \.self) { index in
//          let column = sections[index]
//          
//          VStack(alignment: .leading, spacing: 0) {
//            //            ForEach(column.indices, id: \.self) { columnIndex in
//            //              switch column[columnIndex] {
//            //              case let .title(name, manaCost):
//            //                break
//            //              case let .typeline(value):
//            //                break
//            //              case let .description(text, flavor):
//            //                break
//            //              }
//            //            }
//          }
//        }
//      }
      //        Divider().safeAreaPadding(.leading, nil)
      //
      //        HStack(alignment: .top, spacing: 8.0) {
      //          let edgeInsets = EdgeInsets(
      //            top: 8,
      //            leading: 0,
      //            bottom: section.isLast ? 13 : 8,
      //            trailing: 0
      //          )
      //
      //          switch section.type {
      //          case .title:
      //            TitleView(
      //              name: main.name,
      //              manaCost: main.manaCost
      //            )
      //            .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8.0, trailing: 0))
      //
      //            if let name = alternate?.name, let manaCost = alternate?.manaCost {
      //              Divider()
      //
      //              TitleView(
      //                name: name,
      //                manaCost: manaCost
      //              )
      //              .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8, trailing: 0))
      //            }
      //
      //          case .description:
      //            if section.title1?.isEmptyOrNil() == false || main.flavorText?.isEmptyOrNil() == false {
      //              VStack(alignment: .leading, spacing: 8) {
      //                DescriptionView(section.title1)
      //                FlavorView(main.flavorText)
      //              }
      //              .padding(edgeInsets)
      //            }
      //
      //            if section.title2?.isEmptyOrNil() == false || alternate?.flavorText?.isEmptyOrNil() == false {
      //              Divider()
      //
      //              VStack(alignment: .leading, spacing: 8) {
      //                DescriptionView(section.title2)
      //                FlavorView(alternate?.flavorText)
      //              }
      //              .padding(edgeInsets)
      //            }
      //
      //          case .typeline:
      //            TypelineView(section.title1).padding(edgeInsets)
      //
      //            if let title = section.title2 {
      //              Divider()
      //
      //              TypelineView(title).padding(edgeInsets)
      //            }
      //          }
      //        }
      //        .safeAreaPadding(.horizontal, nil)
      //      }
//    }
  }
  
  init?(
    descriptions: [Content<Card>.Description]
  ) {
    if let arrangement = Arrangement(descriptions: descriptions, isHorizontal: true) {
      self.arrangement = arrangement
    } else {
      return nil
    }
  }
}

extension CardDetailTableView {
  enum Arrangement: Identifiable, Hashable {
    case horizontal([[SectionType]])
    case vertical([[SectionType]])
    
    nonisolated(unsafe) var id: Self {
      return self
    }
    
    init?(descriptions: [Content<Card>.Description], isHorizontal: Bool) {
      if descriptions.count == 1, let main = descriptions.first {
        self = .vertical([
          [
            .title(name: main.name, manaCost: main.manaCost),
            .description(main.text, flavor: main.flavorText),
            .typeline(main.flavorText)
          ]
        ])
      } else if descriptions.count == 2, let main = descriptions.first, let alternate = descriptions.last {
        
        if isHorizontal {
          let mainColumn: [SectionType] = [
            .title(name: main.name, manaCost: main.manaCost),
            .description(main.text, flavor: main.flavorText),
            .typeline(main.flavorText),
          ]
          
          let alternativeColumn: [SectionType] = [
            .title(name: alternate.name, manaCost: alternate.manaCost),
            .description(alternate.text, flavor: alternate.flavorText),
            .typeline(alternate.flavorText)
          ]
          
          self = .horizontal([
            
          ])
        } else {
          let mainColumn: [SectionType] = [
            .title(name: main.name, manaCost: main.manaCost),
            .description(main.text, flavor: main.flavorText),
            .typeline(main.flavorText),
          ]
          
          let alternativeColumn: [SectionType] = [
            .title(name: alternate.name, manaCost: alternate.manaCost),
            .description(alternate.text, flavor: alternate.flavorText),
            .typeline(alternate.flavorText)
          ]
          self = .vertical([mainColumn, alternativeColumn])
        }
      } else {
        return nil
      }
    }
  }
  
  enum SectionType: Identifiable, Hashable {
    case title(name: String, manaCost: [String])
    case description(String?, flavor: String?)
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
