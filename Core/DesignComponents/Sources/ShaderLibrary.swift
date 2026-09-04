//
//  ShaderLibrary.swift
//  DesignComponents
//
//  Created by Jun on 3/9/26.
//


import SwiftUI

public extension ShaderLibrary {
  /// Exposes the Metal shaders compiled in the DesignComponents module.
  static var designComponents: ShaderLibrary {
     return ShaderLibrary.bundle(DesignComponentsResources.bundle)
  }
}
