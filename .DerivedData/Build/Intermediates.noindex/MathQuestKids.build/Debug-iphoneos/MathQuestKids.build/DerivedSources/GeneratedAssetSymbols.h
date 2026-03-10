#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"NP.MathQuestKids";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "AxolotlBackground" asset catalog image resource.
static NSString * const ACImageNameAxolotlBackground AC_SWIFT_PRIVATE = @"AxolotlBackground";

/// The "CandylandBackground" asset catalog image resource.
static NSString * const ACImageNameCandylandBackground AC_SWIFT_PRIVATE = @"CandylandBackground";

/// The "RainbowUnicornBackground" asset catalog image resource.
static NSString * const ACImageNameRainbowUnicornBackground AC_SWIFT_PRIVATE = @"RainbowUnicornBackground";

/// The "StarsSpaceBackground" asset catalog image resource.
static NSString * const ACImageNameStarsSpaceBackground AC_SWIFT_PRIVATE = @"StarsSpaceBackground";

#undef AC_SWIFT_PRIVATE
