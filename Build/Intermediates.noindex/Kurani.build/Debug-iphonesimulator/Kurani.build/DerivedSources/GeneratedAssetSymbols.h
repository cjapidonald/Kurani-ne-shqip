#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"com.example.Kurani";

/// The "Accent" asset catalog color resource.
static NSString * const ACColorNameAccent AC_SWIFT_PRIVATE = @"Accent";

/// The "Accent Color" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"Accent Color";

/// The "AccentLight" asset catalog color resource.
static NSString * const ACColorNameAccentLight AC_SWIFT_PRIVATE = @"AccentLight";

/// The "DarkBackground" asset catalog color resource.
static NSString * const ACColorNameDarkBackground AC_SWIFT_PRIVATE = @"DarkBackground";

/// The "Primary" asset catalog color resource.
static NSString * const ACColorNamePrimary AC_SWIFT_PRIVATE = @"Primary";

/// The "PrimarySurface" asset catalog color resource.
static NSString * const ACColorNamePrimarySurface AC_SWIFT_PRIVATE = @"PrimarySurface";

/// The "TextPrimary" asset catalog color resource.
static NSString * const ACColorNameTextPrimary AC_SWIFT_PRIVATE = @"TextPrimary";

/// The "TextSecondary" asset catalog color resource.
static NSString * const ACColorNameTextSecondary AC_SWIFT_PRIVATE = @"TextSecondary";

/// The "AppIcon" asset catalog image resource.
static NSString * const ACImageNameAppIcon AC_SWIFT_PRIVATE = @"AppIcon";

#undef AC_SWIFT_PRIVATE
