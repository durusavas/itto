#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"ittoApp.durusavas";

/// The "AccentColor1" asset catalog color resource.
static NSString * const ACColorNameAccentColor1 AC_SWIFT_PRIVATE = @"AccentColor1";

/// The "bg1" asset catalog color resource.
static NSString * const ACColorNameBg1 AC_SWIFT_PRIVATE = @"bg1";

/// The "bg2" asset catalog color resource.
static NSString * const ACColorNameBg2 AC_SWIFT_PRIVATE = @"bg2";

/// The "ittoPurple" asset catalog color resource.
static NSString * const ACColorNameIttoPurple AC_SWIFT_PRIVATE = @"ittoPurple";

#undef AC_SWIFT_PRIVATE
