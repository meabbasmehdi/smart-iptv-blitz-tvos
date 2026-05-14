import CoreText
import Foundation

enum FontRegistrar {
    static func registerBundledFonts() {
        AppFontFamily.bundledFontFiles.forEach { fileName in
            guard let url = Bundle.main.url(forResource: fileName, withExtension: "ttf") else {
                return
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
