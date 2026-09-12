import Foundation

/// Where a product's real wrapper photograph lives.
///
/// PackSim (<https://packsim.app>) hosts a photograph of each sealed product at
/// a predictable path and serves it through Cloudflare's image resizer, which
/// means the same source can supply both the full-size wrapper the tear needs
/// and the thumbnail the set's menu wants. Used with permission.
///
/// Coverage is good for anything from roughly 2019 on but thins out for older
/// releases — draft boosters in particular are missing for a lot of pre-2020
/// sets — so every URL here is an upgrade over the drawn wrapper rather than a
/// requirement. Anything that 404s falls through to the next source and then to
/// `BoosterPackArtwork`.
public enum PackArtwork {
  /// Sources for the full-size wrapper, best first.
  ///
  /// Arcane Assets leads: it publishes wrappers at 900x1687, where PackSim's
  /// are a 300x300 square the pack only fills about 141x268 of. Filling a phone
  /// screen from that is roughly a fifth of the detail, and no resampling puts
  /// back what was never photographed. Its packs are photographed at a slight
  /// angle rather than square on, which is the trade being made here — the
  /// slant is the cost of the resolution. PackSim covers what Arcane Assets is
  /// missing, requested at 3x so its upscale at least happens once,
  /// server-side, with a decent filter.
  public static func urls(for product: PackProduct) -> [URL] {
    [
      arcaneAssetsURL(for: product),
      packSimURL(for: product, width: 900, upscaling: true),
    ]
    .compactMap { $0 }
  }

  public static func url(for product: PackProduct) -> URL? {
    urls(for: product).first
  }

  /// A wrapper scaled for a list row or a menu.
  ///
  /// PackSim leads here: at row height its source is already more pixels than
  /// the slot needs, its cut-outs are consistent, and it covers more of the
  /// recent catalogue than Arcane Assets does.
  public static func thumbnailURL(for product: PackProduct, width: Int = 200) -> URL? {
    packSimURL(for: product, width: width, upscaling: false)
  }

  private static func packSimURL(for product: PackProduct, width: Int?, upscaling: Bool) -> URL? {
    let code = product.set.code.lowercased()
    // PackSim files boosters under the same three names the app sells them as.
    let kind = product.kind.rawValue

    var options = ["format=auto", "quality=90"]
    if let width { options.append("width=\(width)") }
    // The resizer defaults to `scale-down`, which will never enlarge; asking
    // for more pixels than the source has needs `fit` saying so explicitly.
    if upscaling { options.append("fit=contain") }

    return URL(
      string: "https://packsim.app/cdn-cgi/image/\(options.joined(separator: ","))/images/boosters/\(code)-\(kind).png"
    )
  }

  private static func arcaneAssetsURL(for product: PackProduct) -> URL? {
    URL(
      string:
        "https://www.arcane-assets.com/sealed_products/\(product.set.code.lowercased())/\(product.kind.rawValue).png"
    )
  }
}
