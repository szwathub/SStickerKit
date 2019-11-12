//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerView.h
//  Author:    Zhiwei Sun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by Cyrex on 2019/11/5
//

#import "SStickerControl.h"
#import "SStickerConfiguration.h"

NS_ASSUME_NONNULL_BEGIN

@class SStickerStyle;
@protocol SStickerDelegate;

#pragma mark -
#pragma mark - SStickerView
@interface SStickerView : UIView

@property (nonatomic, strong, readonly) UIView *contentView;

@property (nonatomic, weak) id<SStickerDelegate> delegate;

@property (nonatomic, strong) id<SStickerConfiguration> sticker;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL maskEnable; // default is YES

- (void)updateStickerConstraints;
- (void)resetStickerConstraints;

@end


#pragma mark -
#pragma mark - SStickerDelegate
@protocol SStickerDelegate <NSObject>
@required
- (SStickerCorner)controlCornerForStickerView:(__kindof SStickerView *)stickerView;

- (SStickerStyle *)styleForStickerView:(__kindof SStickerView *)stickerView byCorner:(SStickerCorner)corner;

- (void)stickerView:(__kindof SStickerView *)stickerView configureBackView:(UIView *)backView;

@optional
- (void)willResetStickerView:(__kindof SStickerView *)stickerView;
- (void)willEditStickerView:(__kindof SStickerView *)stickerView;

- (UIBezierPath *)stickerView:(__kindof SStickerView *)stickerView bezierPathInRect:(CGRect)rect;

@end

NS_ASSUME_NONNULL_END
