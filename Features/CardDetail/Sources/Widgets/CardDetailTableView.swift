import DesignComponents
import Networking
import SwiftUI

struct CardDetailTableView: View {
  let sections: [SectionType]
  
  var body: some View {
    VStack(spacing: 0) {
      ForEach(sections.indices, id: \.self) { index in
        if index != 0 {
          VibrantDivider()
            .safeAreaPadding(.leading, nil)
        }
        
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
          HStack(alignment: .top, spacing: 16.0) { // Bumped spacing to accommodate the overlay line
            TitleView(
              name: name1,
              manaCost: manaCost1
            )
            .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8.0, trailing: 0))
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if let name2, let manaCost2 {
              TitleView(
                name: name2,
                manaCost: manaCost2
              )
              .padding(EdgeInsets(top: 13.0, leading: 0, bottom: 8, trailing: 0))
              .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .safeAreaPadding(.horizontal, nil)
          // Draw the divider here instead of inside the HStack
          .overlay {
            if name2 != nil {
              VibrantVerticalDivider()
            }
          }
          
        case let .typeline(value):
          TypelineView(value)
            .padding(edgeInsets)
            .safeAreaPadding(.horizontal, nil)
          
        case let .typelines(text1, text2):
          HStack(alignment: .top, spacing: 16.0) {
            TypelineView(text1)
              .padding(edgeInsets)
              .frame(maxWidth: .infinity, alignment: .leading)
            
            if let text2 {
              TypelineView(text2)
                .padding(edgeInsets)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          .safeAreaPadding(.horizontal, nil)
          // Draw the divider here instead of inside the HStack
          .overlay {
            if text2 != nil {
              VibrantVerticalDivider()
            }
          }
          
        case let .description(text, flavor):
          if text.isEmpty == false || flavor?.isEmptyOrNil() == false {
            VStack(alignment: .leading, spacing: 8) {
              DescriptionView(text)
              FlavorView(flavor)
            }
            .padding(edgeInsets)
            .safeAreaPadding(.horizontal, nil)
          }
          
        case let .descriptions(text1, flavor1, text2, flavor2):
          HStack(alignment: .top, spacing: 16.0) {
            if text1.isEmpty == false || flavor1?.isEmptyOrNil() == false {
              VStack(alignment: .leading, spacing: 8) {
                DescriptionView(text1)
                  .frame(maxWidth: .infinity)
                FlavorView(flavor1)
              }
              .padding(edgeInsets)
              .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            
            if text2.isEmpty == false || flavor2?.isEmptyOrNil() == false {
              VStack(alignment: .leading, spacing: 8) {
                DescriptionView(text2)
                  .frame(maxWidth: .infinity)
                FlavorView(flavor2)
              }
              .padding(edgeInsets)
              .frame(maxWidth: .infinity, alignment: .topLeading)
            }
          }
          .safeAreaPadding(.horizontal, nil)
          // Draw the divider here instead of inside the HStack
          .overlay {
            if text2.isEmpty == false || flavor2?.isEmptyOrNil() == false {
              VibrantVerticalDivider()
            }
          }
        }
      }
    }
  }
  
  init?(descriptions: [Content.Description]) {
    if descriptions.count == 1, let main = descriptions.first {
      self.sections = [
        .title(main.name, main.manaCost),
        .typeline(main.typeline),
        .description(main.textElements, main.flavorText),
      ]
    } else if descriptions.count == 2, let main = descriptions.first, let alternate = descriptions.last {
      self.sections = [
        .titles(title1: main.name, manaCost1: main.manaCost, title2: alternate.name, manaCost2: alternate.manaCost),
        .typelines(typeline1: main.typeline, typeline2: alternate.typeline),
        .descriptions(description1: main.textElements, flavorText1: main.flavorText, description2: alternate.textElements, flavorText2: alternate.flavorText),
      ]
    } else {
      return nil
    }
  }
}

// MARK: - Subviews

struct VibrantDivider: View {
  @Environment(\.colorScheme) private var colorScheme
  
  var body: some View {
    Divider()
      .opacity(0)
      .overlay(
        Rectangle()
          .fill(colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
          .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
      )
  }
}

// 👇 NEW: Dedicated vertical divider that avoids system `Divider()` bugs
struct VibrantVerticalDivider: View {
  @Environment(\.colorScheme) private var colorScheme
  
  var body: some View {
    Rectangle()
      .fill(colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225))
      .blendMode(colorScheme == .dark ? .plusLighter : .plusDarker)
      .frame(width: 1 / 2) // strictly limits it to a 1px vertical line
  }
}

// MARK: - Extensions

extension CardDetailTableView {
  enum SectionType: Identifiable, Hashable {
    case titles(title1: String, manaCost1: [String], title2: String?, manaCost2: [String]?)
    case title(String, [String])
    case descriptions(description1: [[TextElement]], flavorText1: String?, description2: [[TextElement]], flavorText2: String?)
    case description([[TextElement]], String?)
    case typelines(typeline1: String?, typeline2: String?)
    case typeline(String?)
    
    nonisolated var id: Self {
      return self
    }
  }
}

fileprivate extension String {
  func isEmptyOrNil() -> Bool {
    isEmpty || trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }
}
