/// A kind of printing to sample, and the Scryfall search that finds it.
struct Niche: Sendable, Hashable {
  let name: String
  let query: String

  static let all = [
    Niche(name: "regular", query: "game:paper layout:normal border:black frame:2015 -is:full -frame:showcase -frame:extendedart -is:etched -is:textless"),
    Niche(name: "textless", query: "is:textless game:paper"),
    Niche(name: "borderless", query: "border:borderless game:paper -is:textless"),
    Niche(name: "full art", query: "is:full game:paper"),
    Niche(name: "showcase", query: "frame:showcase game:paper"),
    Niche(name: "extended art", query: "frame:extendedart game:paper"),
    Niche(name: "etched", query: "is:etched game:paper"),
    Niche(name: "white border", query: "border:white game:paper"),
    Niche(name: "retro frame", query: "frame:1997 game:paper"),
    Niche(name: "double-faced", query: "is:dfc game:paper -layout:art_series -layout:double_faced_token"),
    Niche(name: "split", query: "layout:split game:paper"),
    Niche(name: "battle", query: "type:battle game:paper"),
    Niche(name: "token", query: "type:token game:paper -is:dfc"),
  ]
}
