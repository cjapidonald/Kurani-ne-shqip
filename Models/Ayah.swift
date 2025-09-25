import Foundation

struct Ayah: Identifiable, Codable {
    let number: Int
    let text: String

    var id: Int { number }
}
