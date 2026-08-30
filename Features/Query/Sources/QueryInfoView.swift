import DesignComponents
import ComposableArchitecture
import SwiftUI
import Networking

struct QueryInfoView: View {
  @Bindable var store: StoreOf<QueryFeature>
  
  var body: some View {
    Button {
      store.send(.didSelectShowInfo)
    } label: {
      switch store.queryType {
      case let .querySet(set, _):
        HStack(spacing: 5.0) {
          IconLazyImage(URL(string: set.iconSvgUri)).frame(width: 25, height: 25, alignment: .center)
          Text(store.title).multilineTextAlignment(.leading).font(.headline).lineLimit(1)
        }
        .frame(minHeight: 44.0, alignment: .center)
        .padding(EdgeInsets(top: 0, leading: 13.0, bottom: 0, trailing: 16))
        .contentShape(Rectangle())
        
      case .search:
        Text("")
      }
    }
    .buttonStyle(.plain)
    .popover(isPresented: $store.isShowingInfo, attachmentAnchor: .rect(.bounds)) {
      VStack(spacing: 0) {
        ForEach(Array(zip(store.queryType.sections, store.queryType.sections.indices)), id: \.0.id) { section in
          VStack(spacing: 0) {
            section.0.body
              .padding(.vertical, 11.0)
              .safeAreaPadding(.horizontal, systemHorizontalMargin)
            
            if section.1 != store.queryType.sections.count - 1 {
              Divider().safeAreaPadding(.leading, systemHorizontalMargin)
            }
          }
        }
      }
      .padding(.vertical, 11)
      .presentationCompactAdaptation(.popover)
    }
  }
}

private extension QueryType.Section {
  @MainActor var body: some View {
    Group {
      switch self {
      case .titleDetail(let title, let detail):
        HStack {
          Text(title)
          Spacer(minLength: 55)
          Text(detail ?? "").foregroundStyle(.secondary)
        }
        
      case .titleIcon(let title, let iconURL):
        HStack {
          Text(title)
          Spacer(minLength: 55)
          IconLazyImage(
            iconURL,
            tintColor: .secondary
          )
          .frame(width: 21, height: 21, alignment: .center)
        }
        
      case .titleCode(let title, let code):
        HStack {
          Text(title)
          Spacer(minLength: 55)
          Text(code.uppercased()).foregroundStyle(.secondary).fontWidth(.condensed)
        }
      }
    }
  }
}

public extension QueryType {
  // Explicitly mark the nested enum as public
  public enum Section: Identifiable, Sendable {
    case titleDetail(title: String, detail: String?)
    case titleIcon(title: String, iconURL: URL?)
    case titleCode(title: String, code: String)
    
    public var id: String {
      switch self {
      case .titleDetail(let title, let detail):
        return "titleDetail" + title + (detail ?? "")
        
      case .titleIcon(let title, let iconURL):
        return "titleIcon" + title + (iconURL?.absoluteString ?? "")
        
      case .titleCode(let title, let code):
        return "titleCode" + title + code
      }
    }
  }
  
  // Explicitly mark the property as public
  public var sections: [Section] {
    switch self {
    case .search:
      return []
      
    case let .querySet(value, _):
      return [
        .titleIcon(title: String(localized: "Set Symbol"), iconURL: URL(string: value.iconSvgUri)),
        .titleCode(title: String(localized: "Set Code"), code: value.code),
        .titleDetail(title: String(localized: "Release Date"), detail: value.releasedAt),
        .titleDetail(title: String(localized: "Number of Cards"), detail: "\(value.cardCount)"),
      ]
    }
  }
}
