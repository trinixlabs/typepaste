import AppKit

enum TypePasteSettingsTab: String, CaseIterable, Identifiable {
    case general
    case snippets

    var id: Self { self }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .snippets:
            return "Snippet Library"
        }
    }

    var icon: String {
        switch self {
        case .general:
            return "gearshape"
        case .snippets:
            return "text.badge.plus"
        }
    }

    var preferredWindowSize: NSSize {
        switch self {
        case .general:
            return NSSize(width: 720, height: 620)
        case .snippets:
            return NSSize(width: 840, height: 680)
        }
    }
}
