//
//  AmbientWebImage.swift
//  Mooligan
//
//  Created by Jun on 13/4/24.
//

import Nuke
import NukeUI
import SwiftUI
import Shimmer

public struct Cycle {
  let max: Int
  private(set) var current: Int
  
  public init(max: Int) {
    self.max = max
    current = 0
  }
  
  public mutating func next() {
    var _current = current
    _current += 1
    
    if _current >= max {
      _current = 0
    }
    
    self.current = _current
  }
}

public struct AmbientWebImage: View {
  public let url: URL
  private let cornerRadius: CGFloat
  private let blurRadius: CGFloat
  private let offset: CGPoint
  private let scale: CGSize
  private var cycle: Cycle
  private let transformers: [ImageProcessing]
  private let width: CGFloat?
  
  public init(
    url: URL,
    cornerRadius: CGFloat = 9,
    blurRadius: CGFloat = 13,
    offset: CGPoint = CGPoint(x: 0, y: 8),
    scale: CGSize = CGSize(width: 1.05, height: 1.05),
    rotation: CGFloat = 0,
    cycle: Cycle = Cycle(max: 1),
    width: CGFloat? = nil
  ) {
    self.url = url
    self.cornerRadius = width.map { 9 / 144 * $0 } ?? cornerRadius
    self.blurRadius = blurRadius
    self.offset = offset
    self.scale = scale
    self.cycle = cycle
    
    var transformers: [ImageProcessing] = []
    
    if rotation != 0 {
      transformers.append(RotationImageProcessor(degrees: rotation))
    }
    
    if let width {
      transformers.append(.resize(width: width))
    }
    self.width = width
    self.transformers = transformers
  }
  
  public var body: some View {
    ZStack {
      LazyImage(
        request: ImageRequest(
          url: url,
          processors: transformers
        )
      ) { state in
        if let image = state.image {
          image.resizable().aspectRatio(contentMode: .fit)
        }
      }
      .blur(radius: blurRadius, opaque: false)
      .opacity(0.38)
      .scaleEffect(scale)
      .offset(x: offset.x, y: offset.y)
      
      LazyImage(
        request: ImageRequest(
          url: url,
          processors: transformers
        )
      ) { state in
        if state.isLoading {
          RoundedRectangle(cornerRadius: cornerRadius).fill(Color(.systemFill)).shimmering(
            gradient: Gradient(
              colors: [.black.opacity(0.8), .black.opacity(1), .black.opacity(0.8)]
            )
          )
        } else if let image = state.image {
          image.resizable().aspectRatio(contentMode: .fit)
        }
      }
      .clipShape(
        .rect(
          cornerRadii: .init(
            topLeading: cornerRadius,
            bottomLeading: cornerRadius,
            bottomTrailing: cornerRadius,
            topTrailing: cornerRadius
          )
        )
      )
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius).stroke(.separator)
      )
    }
    .frame(width: width ?? 0, height: ((width ?? 0) * 1.3928).rounded())   
  }
}
