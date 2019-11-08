//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerConfiguration.h
//  Author:    Zhiwei Sun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by Cyrex on 2019/11/5
//

#ifndef SStickerConfiguration__H_
#define SStickerConfiguration__H_

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol SStickerConfiguration <NSObject>

@property (nonatomic, assign) BOOL isActive;
@property (nonatomic, assign) CGRect maskRect;

@property (nonatomic, assign) BOOL isFlip;

@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGPoint center;
@property (nonatomic, assign) CGAffineTransform transform;
@property (nonatomic, assign) CGFloat scale;

@end


#endif /* SStickerConfiguration__H_ */
