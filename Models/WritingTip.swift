import Foundation
import SwiftData

@Model
final class WritingTip {
    var id: UUID
    var text: String
    var attribution: String?
    var category: TipCategory

    init(text: String, attribution: String? = nil, category: TipCategory) {
        self.id = UUID()
        self.text = text
        self.attribution = attribution
        self.category = category
    }
}
