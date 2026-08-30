import ComposableArchitecture
import DesignComponents
import Foundation
import Featurist
import Networking
import SwiftUI
import NukeUI
import CoreImage.CIFilterBuiltins


public struct FilmGrainOverlay: View {
  public var opacity: Double
  public var blendMode: BlendMode
  
  public init(opacity: Double = 0.15, blendMode: BlendMode = .overlay) {
    self.opacity = opacity
    self.blendMode = blendMode
  }
  
  public var body: some View {
    Image(decorative: Self.grainImage, scale: 1, orientation: .up)
      .resizable(resizingMode: .tile)
      .blendMode(blendMode)
      .opacity(opacity)
      .allowsHitTesting(false)
  }
  
  // Computes a 128x128 noise tile once statically
  private static let grainImage: CGImage = {
    let noiseFilter = CIFilter.randomGenerator()
    
    // Force grayscale so the grain doesn't look like rainbow TV static
    let grayscale = CIFilter.colorMonochrome()
    grayscale.inputImage = noiseFilter.outputImage
    grayscale.color = CIColor.white
    grayscale.intensity = 1.0
    
    let context = CIContext()
    let bounds = CGRect(x: 0, y: 0, width: 128, height: 128)
    let image = grayscale.outputImage?.cropped(to: bounds)
    
    return context.createCGImage(image!, from: bounds)!
  }()
}

struct QueryView: View {
  @Environment(\.colorScheme) private var colorScheme
  @Environment(\.displayScale) private var displayScale
  @Bindable private var store: StoreOf<QueryFeature>
  @Namespace private var searchMorph
  @Namespace private var statusMorph
  @State private var cardLayoutConfig: CardView.LayoutConfiguration?
  @State private var topBarAvailableWidth: CGFloat? = nil
  
  init(store: StoreOf<QueryFeature>) {
    self.store = store
  }
  
  private var gridItems: [GridItem] {
    [GridItem](
      repeating: GridItem(spacing: 8.0, alignment: .center),
      count: max(1, Int(store.numberOfColumns))
    )
  }
  
  var body: some View {
    ScrollView(.vertical) {
      LazyVGrid(columns: gridItems, spacing: 8.0) {
        if let cardLayoutConfig {
          CardGridContentView(
            store: store,
            layoutConfiguration: cardLayoutConfig
          )
        }
      }
    }
    .onGeometryChange(
      for: CGFloat.self,
      of: { proxy in proxy.size.width },
      action: { width in
        topBarAvailableWidth = width - (systemHorizontalMargin * 2)
        
        let columns = CGFloat(max(1, store.numberOfColumns))
        let totalSpacing = 8.0 * (columns - 1)
        
        let availableWidth = width - (systemHorizontalMargin * 2) - totalSpacing
        let columnWidth = (availableWidth / columns).rounded(.down)
        
        if columnWidth > 0, cardLayoutConfig?.size.width != columnWidth {
          cardLayoutConfig = CardView.LayoutConfiguration(rotation: .portrait, maxWidth: columnWidth)
        }
      }
    )
    .safeAreaBar(edge: .top) {
      if store.mode.shouldHideTopBar == false {
        GlassEffectContainer {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8.0) {
              if !store.isSearchExpanded {
                ColorTypeItemsView(store: store)
                CardTypeItemsView(store: store)
                SortOptionsView(store: store)
              }
              
              SearchBar(
                text: $store.query.name,
                isExpanded: $store.isSearchExpanded,
                isLoading: store.mode.isLoading,
                placeholder: store.searchPrompt
              )
              .glassEffectID("searchBar", in: searchMorph)
            }
            .frame(minWidth: topBarAvailableWidth)
          }
        }
        .animation(.default, value: store.isSearchExpanded)
        .animation(.default, value: store.query)
      }
    }
    .scrollEdgeEffectStyle(.soft, for: .top)
    .contentMargins(
      .all,
      EdgeInsets(top: 0, leading: systemHorizontalMargin, bottom: 13.0, trailing: systemHorizontalMargin),
      for: .scrollContent
    )
    .scrollDisabled(store.mode.isScrollable == false)
    .scrollPosition(.init(get: {
      store.scrollPosition
    }, set:  { _ in }))
    .scrollBounceBehavior(.basedOnSize)
    .navigationTitle(store.mode.isInitialError ? "" : store.title)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(id: "info", placement: .principal) {
        QueryInfoView(store: store).opacity(store.mode.isInitialError ? 0 : 1)
      }
    }
    .background(
      DesignComponentsAsset.backgroundColor.swiftUIColor.ignoresSafeArea()
    )
    .overlay {
      ZStack(alignment: .center) {
        if case let .error(card, isRetrying, isInitial) = store.mode {
          VStack(alignment: .center, spacing: 0) {
            if isInitial {
              // --- INITIAL ERROR STATE ---
              if isRetrying {
                Text("Resolving...")
                  .font(.title3)
                  .fontWidth(.compressed)
                  .fontDesign(.serif)
                  .multilineTextAlignment(.center)
                  .padding(.top, 21.0)
                
                ProgressView()
                  .controlSize(.regular)
                  .padding(.horizontal, 13.0)
                  .frame(minHeight: 44.0)
                  .matchedGeometryEffect(id: "loadingIndicator", in: statusMorph)
                  .padding(.top, 13.0)
                  .padding(.bottom, 89.0)
              } else if let card {
                LazyImage(
                  url: card.getImageURL(type: .artCrop),
                  transaction: Transaction(animation: .smooth)
                ) { state in
                  Color.secondary.opacity(0.2)
                    .overlay {
                      if let image = state.image {
                        image
                          .resizable()
                          .grayscale(1.0)
                          .scaledToFill()
                          .overlay {
                            FilmGrainOverlay(opacity: 0.25, blendMode: .overlay)
                          }
                      }
                    }
                    .shimmering(active: state.image == nil)
                    .blur(radius: state.image == nil ? 34 : 0)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                      RoundedRectangle(cornerRadius: 8)
                        .stroke(
                          (colorScheme == .dark ? Color.white.opacity(0.169) : Color.black.opacity(0.225)).blendMode(
                            colorScheme == .dark ? .plusLighter : .plusDarker
                          ),
                          lineWidth: 1 / displayScale
                        )
                    )
                }
                .padding(.top, 54.0)
                
                Text("Failed to find anything in \"\(store.title)\"")
                  .font(.title3)
                  .fontWidth(.compressed)
                  .fontDesign(.serif)
                  .multilineTextAlignment(.center)
                  .padding(.top, 21.0)
                
                Text(card.flavorText ?? "")
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
              // --- SEARCH / FILTER ERROR STATE ---
              Text("No results found.")
                .font(.title3)
                .fontWidth(.compressed)
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
    .animation(.smooth, value: store.mode.shouldHideTopBar)
    .animation(.smooth, value: store.mode.hasError)
    .animation(.smooth, value: store.mode.isLoading)
    .task { store.send(.viewAppeared) }
  }
}
