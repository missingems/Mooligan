//
//  PriceTag.swift
//  DesignComponents
//
//  Created by Jun on 7/12/25.
//

import SwiftUI

public struct PriceTag: View {
  let displayPrice: String
  
  private let rotation = Double.random(in: -3...3)
  private let offsetX = CGFloat.random(in: -2...2)
  private let offsetY = CGFloat.random(in: -2...2)
  
  public var body: some View {
    ZStack {
      DesignComponentsAsset.priceTag.swiftUIImage
        .resizable()
        .aspectRatio(contentMode: .fit)
        .opacity(0.9)
        .frame(height: 28, alignment: .center)
        .shadow(color: .black.opacity(0.25), radius: 1, x: 0, y: 1)
      
      Text(displayPrice)
        .font(.system(size: 11))
        .foregroundStyle(.black)
        .monospaced()
    }
    .rotationEffect(.degrees(rotation), anchor: .center)
    .offset(x: offsetX, y: offsetY)
  }
  
  public init(displayPrice: String) {
    self.displayPrice = displayPrice
  }
}

#Preview {
  VStack(spacing: 30) {
    PriceTag(displayPrice: "3940.00")
    PriceTag(displayPrice: "125.50")
    PriceTag(displayPrice: "15.99")
  }
}
