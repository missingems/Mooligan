import NukeUI
import ComposableArchitecture
import DesignComponents
import SwiftUI

struct QueryStatusOverlayView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  
  let store: StoreOf<QueryFeature>
  let statusMorph: Namespace.ID
  let topBarAvailableWidth: CGFloat?

  /// Size of the error screen's artwork, which the CRT shader needs in pixels.
  /// Seeded phone-sized rather than `.zero` so the first frame draws something
  /// before the first measurement lands.
  @State private var artSize = CGSize(width: 393.0, height: 500.0)
  
  var body: some View {
    ZStack(alignment: .center) {
      if case let .error(card, isRetrying, isInitial, noInternet) = store.mode {
        VStack(alignment: .center, spacing: 0) {
          if isInitial {
            if isRetrying {
              ProgressView()
                .controlSize(.extraLarge)
                .matchedGeometryEffect(id: "loadingIndicator", in: statusMorph)
              
              Text("Resolving...")
                .font(.title3)
                .fontDesign(.serif)
                .multilineTextAlignment(.center)
                .padding(.top, 8.0)
            } else if card != nil || noInternet {
              // `Color.clear` claims the leftover space the same way the
              // `GeometryReader` here used to, but it stands beside the artwork
              // rather than above it: nothing underneath is re-proposed when the
              // overlay resizes, and the shader still gets the numbers it needs.
              Color.clear
                .onGeometryChange(for: CGSize.self) { $0.size } action: { artSize = $0 }
                .overlay {
                  TimelineView(.animation) { context in
                    let time = context.date.timeIntervalSince1970.truncatingRemainder(dividingBy: 100)

                    Group {
                      if let card {
                        LazyImage(
                          url: card.getImageURL(type: .artCrop),
                          transaction: Transaction(animation: .smooth)
                        ) { state in
                          Color.primary.opacity(0.1)
                            .overlay {
                              if let image = state.image {
                                image
                                  .resizable()
                                  .grayscale(0.815)
                                  .scaledToFill()
                              }
                            }
                        }
                      } else {
                        DesignComponentsAsset.errorPlaceholder.swiftUIImage
                          .resizable()
                          .grayscale(0.815)
                          .scaledToFill()
                      }
                    }
                    .frame(width: artSize.width, height: artSize.height)
                    .layerEffect(
                      ShaderLibrary.designComponents.crtDistortion(
                        .float2(artSize),
                        .float(time),
                        .color(DesignComponentsAsset.backgroundColor.swiftUIColor)
                      ),
                      maxSampleOffset: .zero
                    )
                  }
                }
              .padding(.top, 54.0)
              
              Text("Failed to find \"\(store.title)\"")
                .font(.title3)
                .fontDesign(.serif)
                .multilineTextAlignment(.center)
                .padding(.top, 21.0)
              
              let flavorText: String = {
                if noInternet {
                  "No internet connection."
                } else {
                  card?.flavorText ?? ""
                }
              }()
              
              Text(flavorText)
                .fontDesign(.serif)
                .italic()
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.top, 5.0)
              
              HStack {
                DesignComponentsAsset.t.swiftUIImage.resizable().scaledToFit().frame(height: 24.0)
                Text(": Try Again")
                  .font(.body)
                  .fontWeight(.semibold)
                  .lineLimit(1)
                  .multilineTextAlignment(.center)
              }
              .fixedSize(horizontal: true, vertical: false)
              .padding(.horizontal, 13.0)
              .frame(minHeight: 44.0)
              .glassEffect(.regular.interactive())
              .frame(alignment: .center)
              .onTapGesture {
                store.send(.retry)
              }
              .matchedGeometryEffect(id: "loadingIndicator", in: statusMorph)
              .padding(.top, 13.0)
              .padding(.bottom, 89.0)
            }
          } else {
            Text("No results found.")
              .font(.title3)
              .fontDesign(.serif)
              .multilineTextAlignment(.center)
              .padding(.top, 89.0)
              .padding(.bottom, 89.0)
          }
        }
        .padding(.horizontal, systemHorizontalMargin)
      } else if store.mode.isLoading || store.mode.isPlaceholder {
        Group {
          ProgressView()
            .controlSize(.extraLarge)
        }
        .matchedGeometryEffect(id: "loadingIndicator", in: statusMorph)
        .transition(.opacity)
        .frame(width: topBarAvailableWidth)
      }
    }
  }
}
