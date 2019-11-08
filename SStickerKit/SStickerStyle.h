//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerStyle.h
//  Author:    Zhiwei Sun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by Cyrex on 2019/11/5
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, SStickerAction) {
    SStickerActionNone = 0,
    SStickerActionMirror,
    SStickerActionRotate,
    SStickerActionScale,
    SStickerActionReset,
    SStickerActionTransform,
    SStickerActionRemove
};

@interface SStickerStyle : NSObject

@property (nonatomic, assign) BOOL isEnable;
@property (nonatomic, assign) SStickerAction action;
@property (nonatomic, strong) UIImage *actionImage;

@end

NS_ASSUME_NONNULL_END
