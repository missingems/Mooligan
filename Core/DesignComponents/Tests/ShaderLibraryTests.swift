@testable import DesignComponents
import Metal
import Testing

/// SwiftUI looks a shader up by name only when it draws, and a name that is not in the library fails
/// quietly at runtime rather than at build time, so a renamed or dropped function would go unnoticed
/// until someone looked at the card.
struct ShaderLibraryTests {
  @Test(arguments: ["cardSheen", "carouselEdge", "carouselGlare", "carouselMagnify", "crtDistortion", "holographicFoil"])
  func everyShaderTheViewsCall_shouldBeInTheModulesLibrary(_ name: String) throws {
    let device = try #require(MTLCreateSystemDefaultDevice())
    let library = try device.makeDefaultLibrary(bundle: DesignComponentsResources.bundle)

    #expect(library.makeFunction(name: name) != nil)
  }
}
