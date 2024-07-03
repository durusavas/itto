#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"itto.durusavas";

/// The "AccentColor1" asset catalog color resource.
static NSString * const ACColorNameAccentColor1 AC_SWIFT_PRIVATE = @"AccentColor1";

/// The "logo1" asset catalog image resource.
static NSString * const ACImageNameLogo1 AC_SWIFT_PRIVATE = @"logo1";

#undef AC_SWIFT_PRIVATE
