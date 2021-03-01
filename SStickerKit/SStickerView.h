//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerView.h
//  Author:    Zhiwei Sun @szwathub
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by szwathub on 2019/11/5
//

#import "SStickerControl.h"
#import "SStickerProperty.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const SStickerActionNone;
extern NSString *const SStickerActionMirror;
extern NSString *const SStickerActionRotate;
extern NSString *const SStickerActionScale;
extern NSString *const SStickerActionTransform;

struct SStickerAction {
    NSString *action;
    UIImage *image;
};
typedef struct CG_BOXABLE SStickerAction SStickerAction;

@protocol SStickerDelegate;

// MARK: -
// MARK: - SStickerView
@interface SStickerView : UIView

@property (nonatomic, strong, readonly) UIView *contentView;

@property (nonatomic, weak) id<SStickerDelegate> delegate;

@property (nonatomic, strong) id<SStickerProperty> sticker;
@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) BOOL maskEnable; // default is YES

@property (nonatomic, readonly) UITapGestureRecognizer *tapGesture;

- (void)updateStickerConstraints;
- (void)resetStickerConstraints;

@end


// MARK: -
// MARK: - SStickerDelegate
@protocol SStickerDelegate <NSObject>
@optional
- (void)stickerView:(__kindof SStickerView *)stickerView renderView:(UIView *)backView;

- (SStickerCorner)stickerViewControlCorner:(__kindof SStickerView *)stickerView;

- (SStickerAction)stickerViewAction:(__kindof SStickerView *)stickerView forCorner:(SStickerCorner)corner;

- (void)stickerViewBeginEditing:(__kindof SStickerView *)stickerView;

- (void)stickerViewHasModified:(__kindof SStickerView *)stickerView;

- (void)stickerView:(__kindof SStickerView *)stickerView triggerAction:(NSString *)action;

@end

NS_ASSUME_NONNULL_END
