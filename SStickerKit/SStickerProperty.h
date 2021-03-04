//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerProperty.h
//  Author:    Zhiwei Sun @szwathub
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by szwathub on 2019/11/5
//

#ifndef SStickerProperty__H_
#define SStickerProperty__H_

#import <UIKit/UIKit.h>

@protocol SStickerProperty <NSObject>

@property (nonatomic, assign) BOOL active;

//@property (nonatomic, strong) UIBezierPath *maskPath;

@property (nonatomic, assign) BOOL flip;

//@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat scale;

@property (nonatomic, assign) CGPoint center;

//@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CGFloat a;
@property (nonatomic, assign) CGFloat b;
@property (nonatomic, assign) CGFloat c;
@property (nonatomic, assign) CGFloat d;
@property (nonatomic, assign) CGFloat tx;
@property (nonatomic, assign) CGFloat ty;

@end

#endif /* SStickerProperty__H_ */
