///
///  Copyright © 2019 ZhiweiSun. All rights reserved.
///
///  File name: SStickerKit.h
///  Author:    Zhiwei Sun @szwathub
///  E-mail:    szwathub@gmail.com
///
///  Description:
///
///  History:
///      11/03/2019: Created by szwathub on 11/03/2019
///

#import <UIKit/UIKit.h>

//! Project version number for SStickerKit.
FOUNDATION_EXPORT double SStickerKitVersionNumber;

//! Project version string for SStickerKit.
FOUNDATION_EXPORT const unsigned char SStickerKitVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <SStickerKit/PublicHeader.h>
#if __has_include(<SStickerKit/SStickerKit.h>)
    #import <SStickerKit/SStickerView.h>
    #import <SStickerKit/SStickerProperty.h>
#else
    #import "SStickerView.h"
    #import "SStickerProperty.h"
#endif
