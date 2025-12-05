import Foundation
import SwiftUI

public enum L10n {
    private static let bundle = Bundle.module

    public static func string(_ key: String) -> String {
        NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
    }

    public static func formatted(_ key: String, _ args: CVarArg...) -> String {
        let format = NSLocalizedString(key, tableName: nil, bundle: bundle, value: "", comment: "")
        return String(format: format, locale: .current, arguments: args)
    }

    public static func text(_ key: String) -> Text {
        Text(string(key))
    }

    public static func key(_ key: String) -> LocalizedStringKey {
        LocalizedStringKey(key)
    }
}
