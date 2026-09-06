import Foundation

public struct JSONLineSplitter {
  private var buffer = Data()

  public init() {}

  public mutating func lines(from chunk: Data) -> [Data] {
    buffer.append(chunk)
    var lines: [Data] = []

    while let newline = buffer.firstIndex(of: 0x0A) {
      let line = buffer[buffer.startIndex..<newline]
      buffer.removeSubrange(buffer.startIndex...newline)

      if let trimmed = Self.trimmed(line) {
        lines.append(trimmed)
      }
    }

    return lines
  }

  public mutating func flush() -> Data? {
    defer { buffer = Data() }
    return Self.trimmed(buffer)
  }

  private static func trimmed(_ line: Data) -> Data? {
    var line = line
    if line.last == 0x0D {
      line = line.dropLast()
    }
    return line.isEmpty ? nil : Data(line)
  }
}
