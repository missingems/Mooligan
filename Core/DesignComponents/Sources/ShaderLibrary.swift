//
//  ShaderLibrary.swift
//  DesignComponents
//
//  Created by Jun on 3/9/26.
//


import SwiftUI

public extension ShaderLibrary {
  /// Exposes the Metal shaders compiled in the DesignComponents module.
  public static var designComponents: ShaderLibrary {
    // If you are using SPM (Swift Package Manager):
    return ShaderLibrary.bundle(.module)
    
    // If you are using Tuist / SwiftGen, it will likely be:
    // return ShaderLibrary.bundle(DesignComponentsResources.bundle)
    
    // Or using a class inside the module:
    // return ShaderLibrary.bundle(Bundle(for: SomeClassInDesignComponents.self))
  }
}
