//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerControl.h
//  Author:    Zhiwei Sun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/6: Created by Cyrex on 2019/11/6
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, SStickerCorner) {
    SStickerCornerNone  = 0,
    SStickerTopLeft     = 1 << 0,
    SStickerTopRight    = 1 << 1,
    SStickerBottomLeft  = 1 << 2,
    SStickerBottomRight = 1 << 3,
};

@interface SStickerControl : UIImageView

@property (nonatomic, assign) SStickerCorner corner;
@property (nonatomic, copy) NSString *action;

@end

NS_ASSUME_NONNULL_END
