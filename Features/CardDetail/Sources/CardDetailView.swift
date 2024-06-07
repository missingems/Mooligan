import ComposableArchitecture
import DesignComponents
import Networking
import SwiftUI

struct CardDetailView<Client: MagicCardDetailRequestClient>: View {
  let store: StoreOf<Feature<Client>>
  
  var body: some View {
    GeometryReader { proxy in
      if proxy.size.width > 0 {
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            HeaderView(
              imageURL: store.content.imageURL,
              isFlippable: false,
              orientation: .portrait,
              rotation: 0
            )
            TitleView(
              name: store.content.name,
              manaCosts: store.content.manaCost
            )
            TypelineView(store.content.typeline)
            DescriptionView(store.content.text)
            FlavorView(store.content.flavorText)
            InfoView(
              power: store.content.power,
              toughness: store.content.toughness,
              loyaltyCounters: store.content.loyalty,
              manaValue: store.content.manaValue,
              collectorNumber: "",
              colorIdentity: store.content.colorIdentity,
              setCode: store."",
              setIconURL: nil
            )
          }
        }
        .background { Color(.secondarySystemBackground).ignoresSafeArea() }
      }
    }
    .task {
      store.send(.start)
    }
  }
}

//extension CardDetailView {
//  @ViewBuilder
//  private var content: some View {
//    VStack(alignment: .leading, spacing: 13) {
//      if store.card.layout == .split {
//        multiFaceContentView(leftFace: store.card.cardFaces?.first, rightFace: store.card.cardFaces?.last)
//      } else if store.card.layout == .adventure {
//        multiFaceContentView(leftFace: store.card.cardFaces?.last, rightFace: store.card.cardFaces?.first)
//      } else {
//        nameAndManaCostRow(name: store.configuration?.name, manaCost: store.configuration?.manaCost)
//          .padding(.top, 13.0)
//        typelineRow(typeline: store.configuration?.typeline)
//        textRow(text: store.configuration?.text)
//        flavorTextRow(flavorText: store.configuration?.flavorText)
//      }
//      
//      informationRow
//      
//      if let transformLabel = store.transformLabel {
//        makeDivider()
//        
//        Button {
//          withAnimation(.bouncy) {
//            _ = store.send(.transformTapped)
//          }
//        } label: {
//          HStack {
//            Label(transformLabel, systemImage: "rectangle.portrait.rotate")
//              .font(.headline)
//              .frame(maxWidth: .infinity)
//              .foregroundStyle(Color("ReversedAccent"))
//          }
//        }
//        
//        .buttonStyle(BorderedProminentButtonStyle())
//        .padding(.horizontal, 16.0)
//      }
//      
//      legalityRow
//      marketPriceRow
//      printsRow
//    }
//    .background { Color(.secondarySystemBackground) }
//  }
//  
//  private func header(width: CGFloat) -> some View {
//    let horizontalPadding: CGFloat = (store.configuration?.isLandscape == true ? 34 : 72) * 2
//    let imageWidth = width - horizontalPadding
//    let imageHeight = (store.configuration?.isLandscape == true) ? (imageWidth / 1.3928).rounded() : (imageWidth * 1.3928).rounded()
//    let rotation: CGFloat
//    
//    if store.card.layout == .split {
//      rotation = 90
//    } else if store.card.layout == .flip {
//      if store.configuration?.selectedFaceIndex == 0 {
//        rotation = 0
//      } else {
//        rotation = 180
//      }
//    } else {
//      rotation = 0
//    }
//    
//    return ZStack(alignment: .bottom) {
//      ZStack {
//        AmbientWebImage(
//          url: [store.configuration?.imageURL],
//          cornerRadius: 13,
//          blurRadius: 44.0,
//          offset: CGPoint(x: 0, y: 10),
//          scale: CGSize(width: 1.1, height: 1.1),
//          rotation: rotation,
//          width: imageWidth
//        )
//        
//        if store.card.isFlippable {
//          Button {
//            withAnimation(.bouncy) {
//              _ = store.send(.transformTapped)
//            }
//          } label: {
//            Image(systemName: "rectangle.portrait.rotate").fontWeight(.semibold)
//          }
//          .frame(
//            width: 44.0,
//            height: 44.0,
//            alignment: .center
//          )
//          .background(.thinMaterial)
//          .clipShape(Circle())
//          .overlay(Circle().stroke(Color(.separator), lineWidth: 1 / Main.nativeScale).opacity(0.618))
//          .offset(x: imageWidth / 2 - 27, y: -44)
//        }
//      }
//      .frame(width: imageWidth, height: imageHeight, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
//      .padding(EdgeInsets(top: 13, leading: 0, bottom: 21, trailing: 0))
//      
//      Divider()
//    }
//  }
//  
//  @ViewBuilder
//  func nameAndManaCostRow(name: String?, manaCost: [String]?) -> some View {
//    if let name {
//      HStack(alignment: .top) {
//        Text(name)
//          .font(.headline)
//          .multilineTextAlignment(.leading)
//          .frame(maxWidth: .infinity, alignment: .leading)
//        
//        Spacer()
//        
//        ManaView(
//          identity: manaCost ?? [],
//          size: CGSize(width: 17, height: 17),
//          spacing: 2.0
//        )
//        .offset(CGSize(width: 0, height: 1))
//      }
//      .padding(.horizontal, 16.0)
//    }
//  }
//  
//  @ViewBuilder
//  func typelineRow(typeline: String?, shouldRenderDivider: Bool = true) -> some View {
//    if let typeline {
//      if shouldRenderDivider {
//        makeDivider()
//      }
//      
//      Text(typeline)
//        .font(.headline)
//        .multilineTextAlignment(.leading)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.horizontal, 16.0)
//    }
//  }
//  
//  @ViewBuilder
//  func textRow(text: String?, shouldRenderDivider: Bool = true) -> some View {
//    if let text {
//      if shouldRenderDivider {
//        makeDivider()
//      }
//      
//      TokenizedTextView(text, font: .preferredFont(forTextStyle: .body), paragraphSpacing: 8.0)
//        .multilineTextAlignment(.leading)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.horizontal, 16.0)
//    }
//  }
//  
//  @ViewBuilder
//  func flavorTextRow(flavorText: String?, shouldRenderDivider: Bool = true) -> some View {
//    if let flavorText {
//      if shouldRenderDivider {
//        makeDivider()
//      }
//      
//      Text(flavorText)
//        .font(.body)
//        .fontDesign(.serif)
//        .italic()
//        .foregroundStyle(Color.secondary)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .padding(.horizontal, 16.0)
//    }
//  }
//  
//  @ViewBuilder
//  private var legalityRow: some View {
//    makeDivider()
//    
//    VStack(alignment: .leading) {
//      Text(store.legalityLabel).font(.headline)
//      Text(store.displayReleasedDate).font(.caption).foregroundStyle(.secondary)
//      
//      HStack(spacing: 5.0) {
//        VStack(spacing: 3.0) {
//          ForEach(store.allLegalities.prefix(5).indices, id: \.self) { index in
//            legalityRow(index: index, startingIndex: 0)
//          }
//        }
//        
//        VStack(spacing: 3.0) {
//          ForEach(store.allLegalities.suffix(5).indices, id: \.self) { index in
//            legalityRow(index: index, startingIndex: 5)
//          }
//        }
//      }
//    }
//    .padding(.horizontal, 16.0)
//  }
//  
//  @ViewBuilder
//  private func legalityRow(index: Int, startingIndex: Int) -> some View {
//    let legality = store.allLegalities[index]
//    let value = store.card.legalities.type(legality)
//    let color = value.1?.color.map { $0 }
//    
//    HStack {
//      Text("\(value.1?.localisedDescription ?? "")")
//        .foregroundStyle(Color.white)
//        .frame(minWidth: 0, maxWidth: .infinity).font(.system(size: 12))
//        .padding(.vertical, 5.0)
//        .font(.caption)
//        .background { color }
//        .clipShape(ButtonBorderShape.roundedRectangle)
//        .shadow(color: color?.opacity(0.38) ?? .clear, radius: 5.0)
//      
//      Text("\(value.0)")
//        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
//        .font(.caption)
//        .multilineTextAlignment(.leading)
//    }
//    .background {
//      if (index - startingIndex).isMultiple(of: 2) {
//        Color.quaternarySystemFill.clipShape(ButtonBorderShape.roundedRectangle)
//      } else {
//        Color.clear
//      }
//    }
//  }
//  
//  @ViewBuilder
//  private var informationRow: some View {
//    makeDivider()
//    
//    VStack(alignment: .leading) {
//      Text(String(localized: "Information"))
//        .font(.headline)
//        .padding(.horizontal, 16.0)
//      
//      ScrollView(.horizontal, showsIndicators: false) {
//        LazyHStack(spacing: 5.0) {
//          if let power = store.configuration?.power, let toughness = store.configuration?.toughness {
//            Widget.powerToughness(power: power, toughness: toughness).view
//          }
//          
//          if let loyalty = store.configuration?.loyalty {
//            Widget.loyalty(counters: loyalty).view
//          }
//          
//          Widget.colorIdentity(store.configuration?.colorIdentity ?? []).view
//          
//          if let manaValue = store.configuration?.cmc {
//            Widget.manaValue("\(manaValue)").view
//          }
//          
//          Widget.setCode(store.card.set, iconURL: store.cardSetImageURL).view
//          Widget.collectorNumber(store.card.collectorNumber).view
//        }
//        .padding(.horizontal, 16.0)
//      }
//    }
//  }
//  
//  @ViewBuilder
//  private var illustratorRow: some View {
//    if let artist = store.configuration?.artist {
//      NavigationLink {
//        Text("Artist")
//      } label: {
//        Text(store.illstrautedLabel).font(.headline).tint(.primary)
//        
//        Spacer()
//        
//        HStack(alignment: .center, spacing: 5.0) {
//          Image("artist")
//            .renderingMode(.template)
//            .resizable()
//            .aspectRatio(contentMode: .fit)
//            .frame(height: 12)
//          Text(artist).font(.body)
//        }
//        .tint(.secondary)
//        
//        Image(systemName: "chevron.right")
//          .tint(.tertiaryLabel)
//          .fontWeight(.medium)
//          .imageScale(.small)
//      }
//      .padding(.horizontal, 16.0)
//    }
//  }
//  
//  @ViewBuilder
//  private var marketPriceRow: some View {
//    makeDivider()
//    
//    VStack(alignment: .leading) {
//      Text(String(localized: "Market Prices")).font(.headline)
//      Text(String(localized: "Data from Scryfall")).font(.caption).foregroundStyle(.secondary)
//      
//      HStack(alignment: .center, spacing: 5.0) {
//        let usdPrice = store.configuration?.usdPrice
//        Button {
//          print("Implement View Rulings")
//        } label: {
//          VStack(spacing: 0) {
//            Text("$\(usdPrice ?? "0.00")")
//              .font(usdPrice == nil ? .body : .headline)
//              .monospaced()
//            Text("USD").font(.caption).tint(.secondary)
//          }
//          .frame(maxWidth: .infinity)
//        }
//        .buttonStyle(.bordered)
//        .disabled(usdPrice == nil)
//        
//        let usdFoilPrice = store.configuration?.usdFoilPrice
//        Button {
//          print("Implement View Rulings")
//        } label: {
//          VStack(spacing: 0) {
//            Text("$\(usdFoilPrice ?? "0.00")")
//              .font(usdFoilPrice == nil ? .body : .headline)
//              .monospaced()
//            Text("USD - Foil").font(.caption).tint(.secondary)
//          }
//          .frame(maxWidth: .infinity)
//        }
//        .buttonStyle(.bordered)
//        .disabled(usdFoilPrice == nil)
//        
//        let tixPrice = store.configuration?.tixPrice
//        Button {
//          print("Implement View Rulings")
//        } label: {
//          VStack(spacing: 0) {
//            Text("\(tixPrice ?? "0.00")")
//              .font(tixPrice == nil ? .body : .headline)
//              .monospaced()
//            Text("Tix").font(.caption).tint(.secondary)
//          }
//          .frame(maxWidth: .infinity)
//        }
//        .buttonStyle(.bordered)
//        .disabled(tixPrice == nil)
//      }
//    }
//    .padding(.horizontal, 16.0)
//  }
//  
//  @ViewBuilder
//  private var printsRow: some View {
//    makeDivider()
//    
//    VStack(alignment: .leading) {
//      Text(String(localized: "Prints")).font(.headline).padding(.horizontal, 16.0)
//      Text(String(localized: "\(store.prints.count) Results")).font(.caption).foregroundStyle(.secondary).padding(.horizontal, 16.0)
//      
//      ScrollView(.horizontal, showsIndicators: false) {
//        LazyHStack {
//          ForEach(store.prints) { card in
//            NavigationCardImageView(
//              imageURLs: card.imageURLs,
//              linkState: Feature.Path.State.showCard(CardFeature.State(card: card, cardSetImageURL: store.cardSetImageURL)),
//              shouldFlipOnTransform: card.isRotatable,
//              shouldShowTransformButton: card.isFlippable,
//              width: 144
//            ) {
//              Group {
//                if let usd = card.getPrice(for: .usd) {
//                  PillText(
//                    "$\(usd)",
//                    insets: EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)
//                  )
//                } else if let usdFoil = card.getPrice(for: .usdFoil) {
//                  PillText(
//                    "$\(usdFoil)",
//                    insets: EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5)
//                  )
//                } else {
//                  PillText(
//                    "#\(card.collectorNumber)".uppercased(),
//                    insets: EdgeInsets(top: 3, leading: 5, bottom: 3, trailing: 5),
//                    background: Color.clear
//                  )
//                }
//              }
//              .font(.caption)
//              .fontWeight(.medium)
//              .monospaced()
//            }
//          }
//        }
//        .padding(.horizontal, 16.0)
//      }
//      .scrollClipDisabled(true)
//    }
//  }
//  
//  private func makeDivider() -> some View {
//    Divider().padding(.leading, 16.0)
//  }
//}
