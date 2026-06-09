import AppKit

enum TypePasteSettingsTab: String, CaseIterable, Identifiable {
    case general
    case snippets
    case about

    var id: Self { self }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .snippets:
            return "Snippet Library"
        case .about:
            return "About"
        }
    }

    var icon: String {
        switch self {
        case .general:
            return "gearshape"
        case .snippets:
            return "text.badge.plus"
        case .about:
            return "info.circle"
        }
    }

    var preferredWindowSize: NSSize {
        switch self {
        case .general:
            return NSSize(width: 840, height: 620)
        case .snippets:
            return NSSize(width: 840, height: 680)
        case .about:
            return NSSize(width: 840, height: 420)
        }
    }
}
