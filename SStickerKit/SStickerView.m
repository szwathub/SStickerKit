//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerView.m
//  Author:    Zhiwei Sun @Cyrex
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by Cyrex on 2019/11/5
//

#import "SStickerView.h"

#import "SStickerStyle.h"

@interface SStickerView () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong) NSArray<SStickerControl *> *stickerControls;

@property (nonatomic, weak) UIImageView *rotateformCtrl;
@property (nonatomic, weak) UIImageView *scaleformCtrl;
@property (nonatomic, weak) UIImageView *transformCtrl;

@property (nonatomic) CGPoint lastCtrlPoint;
@property (nonatomic) CGFloat initialAngle;

@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;

@end

@implementation SStickerView
#pragma mark - Life Cycle
- (instancetype)init {
    if (self= [super init]) {
        [self addGestureRecognizer:self.panGesture];
        [self addGestureRecognizer:self.tapGesture];
        [self.tapGesture requireGestureRecognizerToFail:self.panGesture];
    }
    
    return self;
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        int count = (int)self.subviews.count;
        for (int i = count - 1; i >= 0; i--) {
            UIView *subView = self.subviews[i];
            CGPoint p = [subView convertPoint:point fromView:self];
            if (CGRectContainsPoint(subView.bounds, p)) {
                if (subView.isHidden) {
                    continue;
                }
                return subView;
            }
        }
    }

    return view;
}


#pragma mark - Override
- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self addSubview:self.backView];
    [self.delegate stickerView:self configureBackView:self.backView];

    [self addSubview:self.contentView];

    SStickerCorner corner = [self.delegate controlCornerForStickerView:self];
    [self.stickerControls enumerateObjectsUsingBlock:^(SStickerControl *control, NSUInteger idx, BOOL *stop) {
        if (corner & control.corner) {
            SStickerStyle *style = [self.delegate styleForStickerView:self byCorner:control.corner];
            control.image = style.actionImage;
            control.userInteractionEnabled = style.isEnable;
            [self configControl:control withAction:style.action];
            [self addSubview:control];
        }
    }];
}


#pragma mark - Public Methods
- (void)updateStickerConstraints {
    self.center    = self.stickerModel.center;
    self.transform = self.stickerModel.transform;
    if (self.stickerModel.isFlip) {
        self.contentView.transform = CGAffineTransformScale(self.contentView.transform, -1.0, 1.0);
    }

    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.stickerModel.maskRect];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = self.bounds;
    maskLayer.path = maskPath.CGPath;
    self.contentView.layer.mask = maskLayer;

    [self fitCtrlScaleX:self.stickerModel.scale scaleY:self.stickerModel.scale];
}

- (void)resetStickerConstraints {
    self.center    = self.stickerModel.center;
    self.transform = self.stickerModel.transform;
    self.contentView.transform = CGAffineTransformIdentity;
    self.contentView.layer.mask = nil;
    for (SStickerControl *control in self.stickerControls) {
        control.transform = CGAffineTransformIdentity;
    }
}


#pragma mark - Private Methods
- (void)configControl:(UIImageView *)control withAction:(SStickerAction)action {
    if (SStickerActionMirror == action) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(mirrorControlTap:)];
        [control addGestureRecognizer:tapGesture];
    } else if (SStickerActionRotate == action) {
        self.rotateformCtrl = control;
        UIPanGestureRecognizer *rotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(rotateControlTap:)];
        [control addGestureRecognizer:rotateGesture];
    } else if (SStickerActionScale == action) {
        self.scaleformCtrl = control;
        UIPanGestureRecognizer *scaleGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(sacleControlTap:)];
        [control addGestureRecognizer:scaleGesture];
        
    } else if (SStickerActionReset == action) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(resetControlTap:)];
        [control addGestureRecognizer:tapGesture];
    } else if (SStickerActionTransform == action) {
        self.transformCtrl = control;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(transformCtrlPan:)];
        [control addGestureRecognizer:panGesture];
    }
}

- (void)rotateAroundPointWithCtrlPoint:(CGPoint)ctrlPoint {
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x - (self.center.x - oPoint.x),
                              self.center.y - (self.center.y - oPoint.y));
    

    float angle = atan2(self.center.y - ctrlPoint.y, ctrlPoint.x - self.center.x);
    float lastAngle = atan2(self.center.y - self.lastCtrlPoint.y, self.lastCtrlPoint.x - self.center.x);
    angle = - angle + lastAngle;
    self.transform = CGAffineTransformRotate(self.transform, angle);

    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));
    
    self.stickerModel.center    = self.center;
    self.stickerModel.transform = self.transform;
}

- (void)scaleFitWithCtrlPoint:(CGPoint)ctrlPoint {
    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = oPoint;

    CGFloat preDistance = [self distanceWithStartPoint:self.center endPoint:self.lastCtrlPoint];
    CGFloat newDistance = [self distanceWithStartPoint:self.center endPoint:ctrlPoint];
    CGFloat scale = newDistance / preDistance;

    self.transform = CGAffineTransformScale(self.transform, scale, scale);
    [self fitCtrlScaleX:scale scaleY:scale];

    oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));
    
    self.stickerModel.center    = self.center;
    self.stickerModel.scale     = scale * self.stickerModel.scale;
    self.stickerModel.transform = self.transform;
    [self configMaskView];
}

- (CGPoint)getRealOriginalPoint {
    return CGPointMake(self.bounds.size.width * .5, self.bounds.size.height * .5);
}

- (void)fitCtrlScaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY {
    self.contentView.layer.borderWidth = self.contentView.layer.borderWidth / scaleX;
    for (SStickerControl *control in self.stickerControls) {
        control.transform = CGAffineTransformScale(control.transform, 1 / scaleX, 1 / scaleY);
    }
}

- (CGFloat)distanceWithStartPoint:(CGPoint)start endPoint:(CGPoint)end {
    CGFloat x = start.x - end.x;
    CGFloat y = start.y - end.y;
    return sqrt(x * x + y * y);
}

- (void)configMaskView {
    if (self.delegate && [self.delegate respondsToSelector:@selector(stickerView:rectIntersection:)]) {
        self.stickerModel.maskRect = [self.delegate stickerView:self rectIntersection:self.frame];
        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRect:self.stickerModel.maskRect];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = self.bounds;
        maskLayer.path = maskPath.CGPath;
        self.contentView.layer.mask = maskLayer;
    }
}


#pragma mark - UIPanGestureRecognizer
- (void)mirrorControlTap:(UITapGestureRecognizer *)gesture {
    [UIView animateWithDuration:.25f animations:^{
        self.contentView.transform = CGAffineTransformScale(self.contentView.transform, -1.0, 1.0);
    } completion:^(BOOL finished) {
        self.stickerModel.isFlip = !self.stickerModel.isFlip;
    }];
}

- (void)resetControlTap:(UITapGestureRecognizer *)gesture {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willResetStickerView:)]) {
        [self.delegate willResetStickerView:self];
    }
}

- (void)rotateControlTap:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastCtrlPoint = [self convertPoint:self.rotateformCtrl.center toView:self.superview];
        return;
    }

    CGPoint ctrlPoint = [gesture locationInView:self.superview];
    [self rotateAroundPointWithCtrlPoint:ctrlPoint];
    
    self.lastCtrlPoint = ctrlPoint;
}

- (void)sacleControlTap:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastCtrlPoint = [self convertPoint:self.scaleformCtrl.center toView:self.superview];
        return;
    }
    
    CGPoint ctrlPoint = [gesture locationInView:self.superview];

    [self scaleFitWithCtrlPoint:ctrlPoint];
    self.lastCtrlPoint = ctrlPoint;
}

- (void)transformCtrlPan:(UIPanGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.lastCtrlPoint = [self convertPoint:self.transformCtrl.center toView:self.superview];
        return;
    }

    CGPoint ctrlPoint = [gesture locationInView:self.superview];

    [self scaleFitWithCtrlPoint:ctrlPoint];
    [self rotateAroundPointWithCtrlPoint:ctrlPoint];
    
    self.lastCtrlPoint = ctrlPoint;
}



- (void)pan:(UIPanGestureRecognizer *)gesture {
    if (!self.isActive) {
        return ;
    }

    CGPoint pt = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + pt.x , self.center.y + pt.y);
    [gesture setTranslation:CGPointMake(0, 0) inView:self.superview];

    self.stickerModel.center = self.center;
    [self configMaskView];
}

- (void)tap:(UITapGestureRecognizer *)gesture {
    if (self.delegate && [self.delegate respondsToSelector:@selector(willEditStickerView:)]) {
        [self.delegate willEditStickerView:self];
    }
}


#pragma mark - UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer.view == self) {
        CGPoint p = [touch locationInView:self];
        for (SStickerControl *control in self.stickerControls) {
            if (CGRectContainsPoint(control.frame, p)) {
                return NO;
            }
        }
    }

    return YES;
}


#pragma mark - Setters
- (void)setIsActive:(BOOL)isActive {
    _isActive = isActive;
    
    for (SStickerControl *control in self.stickerControls) {
        control.hidden = !_isActive;
    }
    self.backView.hidden = !_isActive;
}


#pragma mark - Getters
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    }
    
    return _backView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds))];
    }
    
    return _contentView;
}

- (NSArray<SStickerControl *> *)stickerControls {
    if (!_stickerControls) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (NSInteger index = 0; index < 4; index++) {
            SStickerControl *control = [[SStickerControl alloc] init];
            if (0 == index) {
                control.corner = SStickerTopLeft;
                control.frame  = CGRectMake(-10, -10, 20, 20);
            } else if (1 == index) {
                control.corner = SStickerTopRight;
                control.frame  = CGRectMake(-10 + CGRectGetWidth(self.bounds), -10, 20, 20);
            } else if (2 == index) {
                control.corner = SStickerBottomLeft;
                control.frame  = CGRectMake(-10, -10 + CGRectGetHeight(self.bounds), 20, 20);
            } else {
                control.corner = SStickerBottomRight;
                control.frame  = CGRectMake(-10 + CGRectGetWidth(self.bounds), -10 + CGRectGetHeight(self.bounds), 20, 20);
            }

            [tmp addObject:control];
        }
        
        _stickerControls = [tmp copy];
    }

    return _stickerControls;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(pan:)];
        _panGesture.delegate = self;
        _panGesture.minimumNumberOfTouches = 1;
        _panGesture.maximumNumberOfTouches = 2;
    }

    return _panGesture;
}

- (UITapGestureRecognizer *)tapGesture {
    if (!_tapGesture) {
        _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(tap:)];
        _tapGesture.delegate = self;
    }

    return _tapGesture;
}

@end
