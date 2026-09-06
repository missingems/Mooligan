import Compression
import Foundation

enum GzipFixture {
  struct Options {
    var filename: String?
    var comment: String?
    var extraField: [UInt8]?

    init(filename: String? = nil, comment: String? = nil, extraField: [UInt8]? = nil) {
      self.filename = filename
      self.comment = comment
      self.extraField = extraField
    }
  }

  static func compress(_ data: Data, options: Options = Options()) throws -> Data {
    var flags: UInt8 = 0
    if options.extraField != nil { flags |= 0x04 }
    if options.filename != nil { flags |= 0x08 }
    if options.comment != nil { flags |= 0x10 }

    var output = Data([0x1F, 0x8B, 0x08, flags, 0, 0, 0, 0, 0, 0x03])

    if let extraField = options.extraField {
      output.append(UInt8(extraField.count & 0xFF))
      output.append(UInt8((extraField.count >> 8) & 0xFF))
      output.append(contentsOf: extraField)
    }
    if let filename = options.filename {
      output.append(contentsOf: Array(filename.utf8) + [0])
    }
    if let comment = options.comment {
      output.append(contentsOf: Array(comment.utf8) + [0])
    }

    output.append(try (data as NSData).compressed(using: .zlib) as Data)

    let crc = crc32(data)
    let size = UInt32(truncatingIfNeeded: data.count)
    for value in [crc, size] {
      output.append(contentsOf: (0..<4).map { UInt8((value >> ($0 * 8)) & 0xFF) })
    }

    return output
  }

  static func jsonLines(_ objects: [[String: Any]]) throws -> Data {
    var output = Data()
    for object in objects {
      output.append(try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]))
      output.append(0x0A)
    }
    return output
  }

  private static func crc32(_ data: Data) -> UInt32 {
    var crc: UInt32 = 0xFFFF_FFFF
    for byte in data {
      crc ^= UInt32(byte)
      for _ in 0..<8 {
        crc = (crc >> 1) ^ (0xEDB8_8320 & (crc & 1 == 1 ? 0xFFFF_FFFF : 0))
      }
    }
    return crc ^ 0xFFFF_FFFF
  }
}
