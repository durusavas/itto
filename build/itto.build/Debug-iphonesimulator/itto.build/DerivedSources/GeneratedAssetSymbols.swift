import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor1" asset catalog color resource.
    static let accentColor1 = DeveloperToolsSupport.ColorResource(name: "AccentColor1", bundle: resourceBundle)

    /// The "bg1" asset catalog color resource.
    static let bg1 = DeveloperToolsSupport.ColorResource(name: "bg1", bundle: resourceBundle)

    /// The "bg2" asset catalog color resource.
    static let bg2 = DeveloperToolsSupport.ColorResource(name: "bg2", bundle: resourceBundle)

    /// The "ittoPurple" asset catalog color resource.
    static let ittoPurple = DeveloperToolsSupport.ColorResource(name: "ittoPurple", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor1" asset catalog color.
    static var accentColor1: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accentColor1)
#else
        .init()
#endif
    }

    /// The "bg1" asset catalog color.
    static var bg1: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bg1)
#else
        .init()
#endif
    }

    /// The "bg2" asset catalog color.
    static var bg2: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bg2)
#else
        .init()
#endif
    }

    /// The "ittoPurple" asset catalog color.
    static var ittoPurple: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .ittoPurple)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor1" asset catalog color.
    static var accentColor1: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accentColor1)
#else
        .init()
#endif
    }

    /// The "bg1" asset catalog color.
    static var bg1: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bg1)
#else
        .init()
#endif
    }

    /// The "bg2" asset catalog color.
    static var bg2: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bg2)
#else
        .init()
#endif
    }

    /// The "ittoPurple" asset catalog color.
    static var ittoPurple: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .ittoPurple)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor1" asset catalog color.
    static var accentColor1: SwiftUI.Color { .init(.accentColor1) }

    /// The "bg1" asset catalog color.
    static var bg1: SwiftUI.Color { .init(.bg1) }

    /// The "bg2" asset catalog color.
    static var bg2: SwiftUI.Color { .init(.bg2) }

    /// The "ittoPurple" asset catalog color.
    static var ittoPurple: SwiftUI.Color { .init(.ittoPurple) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor1" asset catalog color.
    static var accentColor1: SwiftUI.Color { .init(.accentColor1) }

    /// The "bg1" asset catalog color.
    static var bg1: SwiftUI.Color { .init(.bg1) }

    /// The "bg2" asset catalog color.
    static var bg2: SwiftUI.Color { .init(.bg2) }

    /// The "ittoPurple" asset catalog color.
    static var ittoPurple: SwiftUI.Color { .init(.ittoPurple) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

