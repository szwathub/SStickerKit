//
//  Copyright © 2019 ZhiweiSun. All rights reserved.
//
//  File name: SStickerView.m
//  Author:    Zhiwei Sun @szwathub
//  E-mail:    szwathub@gmail.com
//
//  Description:
//
//  History:
//      2019/11/5: Created by szwathub on 2019/11/5
//

#import "SStickerView.h"

NSString *const SStickerActionNone      = @"com.szwathub.stickerkit.action.none";
NSString *const SStickerActionMirror    = @"com.szwathub.stickerkit.action.mirror";
NSString *const SStickerActionRotate    = @"com.szwathub.stickerkit.action.rotate";
NSString *const SStickerActionScale     = @"com.szwathub.stickerkit.action.scale";
NSString *const SStickerActionTransform = @"com.szwathub.stickerkit.action.transform";

@interface SStickerView () <UIGestureRecognizerDelegate> {
    // private
    struct {
        unsigned int viewRenderBackView :1;
        unsigned int viewControlCorner :1;
        unsigned int viewActionForCorner :1;
        unsigned int viewBeginEditing :1;
        unsigned int viewHasModified :1;
        unsigned int viewTriggerAction :1;
    }_delegateFlags;
}

@property (nonatomic, strong) UIView *backView;

@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, strong) NSArray<SStickerControl *> *stickerControls;

@property (nonatomic, weak) UIImageView *rotateformCtrl;
@property (nonatomic, weak) UIImageView *scaleformCtrl;
@property (nonatomic, weak) UIImageView *transformCtrl;

@property (nonatomic) CGPoint lastCtrlPoint;
@property (nonatomic) CGFloat initialAngle;

@property (nonatomic) UIPanGestureRecognizer *panGesture;
@property (nonatomic) UITapGestureRecognizer *tapGesture;
@property (nonatomic) UIRotationGestureRecognizer *rotateGesture;
@property (nonatomic) UIPinchGestureRecognizer *scaleGesture;

@end

@implementation SStickerView
// MARK: - Life Cycle
- (instancetype)init {
    if (self= [super init]) {
        self.maskEnable = YES;

        [self addGestureRecognizer:self.panGesture];
        [self addGestureRecognizer:self.tapGesture];
        [self addGestureRecognizer:self.rotateGesture];
        [self addGestureRecognizer:self.scaleGesture];
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


// MARK: - Override
- (void)layoutSubviews {
    [super layoutSubviews];

    [self addSubview:self.backView];
    self.backView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));

    if (_delegateFlags.viewRenderBackView) {
        [self.delegate stickerView:self renderView:self.backView];
    }

    [self addSubview:self.maskView];

    [self.maskView addSubview:self.contentView];
    self.contentView.frame = CGRectMake(0, 0, CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds));

    if (_delegateFlags.viewControlCorner) {
        SStickerCorner corner = [self.delegate stickerViewControlCorner:self];
        [self.stickerControls enumerateObjectsUsingBlock:^(SStickerControl *control, NSUInteger idx, BOOL *stop) {
            if (corner & control.corner && _delegateFlags.viewActionForCorner) {
                SStickerAction action = [self.delegate stickerViewAction:self forCorner:control.corner];
                control.image  = action.image;
                control.userInteractionEnabled = YES;
                control.action = action.action;
                if (0 == idx) {
                    control.frame  = CGRectMake(-10, -10, 20, 20);
                } else if (1 == idx) {
                    control.frame  = CGRectMake(-10 + CGRectGetWidth(self.bounds), -10, 20, 20);
                } else if (2 == idx) {
                    control.frame  = CGRectMake(-10, -10 + CGRectGetHeight(self.bounds), 20, 20);
                } else {
                    control.frame  = CGRectMake(-10 + CGRectGetWidth(self.bounds), -10 + CGRectGetHeight(self.bounds), 20, 20);
                }

                [self configControl:control withAction:action.action];
                [self addSubview:control];
            }
        }];
    }
}


// MARK: - Public Methods
- (void)updateStickerConstraints {
    self.active  = self.sticker.active;

    self.center    = self.sticker.center;

//    self.transform = self.sticker.transform;
    self.transform = CGAffineTransformMake(self.sticker.a, self.sticker.b,
                                           self.sticker.c, self.sticker.d,
                                           self.sticker.tx, self.sticker.ty);
    if (self.sticker.flip) {
        self.contentView.transform = CGAffineTransformScale(self.contentView.transform, -1.0, 1.0);
    }

//    if (!self.sticker.maskPath.isEmpty && self.maskEnable) {
//        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
//        maskLayer.frame = self.bounds;
//        maskLayer.path = self.sticker.maskPath.CGPath;
//        self.maskView.layer.mask = maskLayer;
//    }

    [self fitCtrlScaleX:self.sticker.scale scaleY:self.sticker.scale];
}

- (void)resetStickerConstraints {
    self.center    = self.sticker.center;
//    self.transform = self.sticker.transform;
    self.transform = CGAffineTransformMake(self.sticker.a, self.sticker.b,
                                           self.sticker.c, self.sticker.d,
                                           self.sticker.tx, self.sticker.ty);
    self.contentView.transform  = CGAffineTransformIdentity;
    self.contentView.layer.mask = nil;
    for (SStickerControl *control in self.stickerControls) {
        control.transform = CGAffineTransformIdentity;
    }
}


// MARK: - Private Methods
- (void)configControl:(SStickerControl *)control withAction:(NSString *)action {
    if ([SStickerActionMirror isEqualToString:action]) {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(mirrorControlTap:)];
        [control addGestureRecognizer:tapGesture];
    } else if ([SStickerActionRotate isEqualToString:action]) {
        self.rotateformCtrl = control;
        UIPanGestureRecognizer *rotateGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(rotateControlTap:)];
        [control addGestureRecognizer:rotateGesture];
    } else if ([SStickerActionScale isEqualToString:action]) {
        self.scaleformCtrl = control;
        UIPanGestureRecognizer *scaleGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(sacleControlTap:)];
        [control addGestureRecognizer:scaleGesture];

    } else if ([SStickerActionTransform isEqualToString:action]) {
        self.transformCtrl = control;
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(transformCtrlPan:)];
        [control addGestureRecognizer:panGesture];
    } else {
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(userDefineAction:)];
        [control addGestureRecognizer:tapGesture];
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

    self.sticker.center    = self.center;
//    self.sticker.transform = self.transform;
    self.sticker.a = self.transform.a;
    self.sticker.b = self.transform.b;
    self.sticker.c = self.transform.c;
    self.sticker.d = self.transform.d;
    self.sticker.tx = self.transform.tx;
    self.sticker.ty = self.transform.ty;

    if (_delegateFlags.viewHasModified) {
        [self.delegate stickerViewHasModified:self];
    }
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

    self.sticker.center    = self.center;
    self.sticker.scale     = scale * self.sticker.scale;
//    self.sticker.transform = self.transform;
    self.sticker.a = self.transform.a;
    self.sticker.b = self.transform.b;
    self.sticker.c = self.transform.c;
    self.sticker.d = self.transform.d;
    self.sticker.tx = self.transform.tx;
    self.sticker.ty = self.transform.ty;

    if (_delegateFlags.viewHasModified) {
        [self.delegate stickerViewHasModified:self];
    }
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


// MARK: - UIPanGestureRecognizer
- (void)userDefineAction:(UITapGestureRecognizer *)gesture {
    SStickerControl *control = (SStickerControl *)gesture.view;

    if (_delegateFlags.viewTriggerAction) {
        [self.delegate stickerView:self triggerAction:control.action];
    }
}

- (void)mirrorControlTap:(UITapGestureRecognizer *)gesture {
    [UIView animateWithDuration:.25f animations:^{
        self.contentView.transform = CGAffineTransformScale(self.contentView.transform, -1.0, 1.0);
    } completion:^(BOOL finished) {
        self.sticker.flip = !self.sticker.flip;
    }];
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
    if (!self.active) {
        return ;
    }

    CGPoint pt = [gesture translationInView:self.superview];
    self.center = CGPointMake(self.center.x + pt.x , self.center.y + pt.y);
    [gesture setTranslation:CGPointMake(0, 0) inView:self.superview];

    self.sticker.center = self.center;

    if (_delegateFlags.viewHasModified) {
        [self.delegate stickerViewHasModified:self];
    }
}

- (void)tap:(UITapGestureRecognizer *)gesture {
    if (_delegateFlags.viewBeginEditing) {
        [self.delegate stickerViewBeginEditing:self];
    }
}

- (void)rotate:(UIRotationGestureRecognizer *)gesture {
    if (!self.active) {
        return ;
    }

    CGFloat angle = gesture.rotation;
    gesture.rotation = 0.f;
    self.transform = CGAffineTransformRotate(self.transform, angle);

    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));

    self.sticker.center    = self.center;
//    self.sticker.transform = self.transform;
    self.sticker.a = self.transform.a;
    self.sticker.b = self.transform.b;
    self.sticker.c = self.transform.c;
    self.sticker.d = self.transform.d;
    self.sticker.tx = self.transform.tx;
    self.sticker.ty = self.transform.ty;
}

- (void)scale:(UIPinchGestureRecognizer *)gesture {
    if (!self.active) {
        return ;
    }

    CGFloat scale = gesture.scale;
    gesture.scale = 1.0;

    self.transform = CGAffineTransformScale(self.transform, scale, scale);
    [self fitCtrlScaleX:scale scaleY:scale];

    CGPoint oPoint = [self convertPoint:[self getRealOriginalPoint] toView:self.superview];
    self.center = CGPointMake(self.center.x + (self.center.x - oPoint.x),
                              self.center.y + (self.center.y - oPoint.y));

    self.sticker.center    = self.center;
    self.sticker.scale     = scale * self.sticker.scale;
//    self.sticker.transform = self.transform;
    self.sticker.a = self.transform.a;
    self.sticker.b = self.transform.b;
    self.sticker.c = self.transform.c;
    self.sticker.d = self.transform.d;
    self.sticker.tx = self.transform.tx;
    self.sticker.ty = self.transform.ty;
}


// MARK: - UIGestureRecognizerDelegate
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


// MARK: - Setters
- (void)setActive:(BOOL)active {
    _active = active;

    for (SStickerControl *control in self.stickerControls) {
        control.hidden = !_active;
    }
    self.backView.hidden = !_active;
}

- (void)setDelegate:(id<SStickerDelegate>)delegate {
    _delegate = delegate;

    _delegateFlags.viewControlCorner   = [delegate respondsToSelector:@selector(stickerViewControlCorner:)];
    _delegateFlags.viewActionForCorner = [delegate respondsToSelector:@selector(stickerViewAction:forCorner:)];
    _delegateFlags.viewRenderBackView  = [delegate respondsToSelector:@selector(stickerView:renderView:)];
    _delegateFlags.viewBeginEditing    = [delegate respondsToSelector:@selector(stickerViewBeginEditing:)];
    _delegateFlags.viewHasModified     = [delegate respondsToSelector:@selector(stickerViewHasModified:)];
    _delegateFlags.viewTriggerAction   = [delegate respondsToSelector:@selector(stickerView:triggerAction:)];
}


// MARK: - Getters
- (UIView *)backView {
    if (!_backView) {
        _backView = [[UIView alloc] initWithFrame:self.bounds];
    }

    return _backView;
}

- (UIView *)maskView {
    if (!_maskView) {
        _maskView = [[UIView alloc] initWithFrame:self.bounds];
    }

    return _maskView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:self.bounds];
    }

    return _contentView;
}

- (NSArray<SStickerControl *> *)stickerControls {
    if (!_stickerControls) {
        NSMutableArray *stickerControls = [NSMutableArray array];
        for (NSInteger index = 0; index < 4; index++) {
            SStickerControl *control = [[SStickerControl alloc] init];
            control.corner = 1 << index;

            [stickerControls addObject:control];
        }

        _stickerControls = [stickerControls copy];
    }

    return _stickerControls;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                              action:@selector(pan:)];
        _panGesture.delegate = self;
        _panGesture.minimumNumberOfTouches = 1;
        _panGesture.maximumNumberOfTouches = 1;
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

- (UIRotationGestureRecognizer *)rotateGesture {
    if (!_rotateGesture) {
        _rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(rotate:)];
    }

    return _rotateGesture;
}

- (UIPinchGestureRecognizer *)scaleGesture {
    if (!_scaleGesture) {
        _scaleGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                  action:@selector(scale:)];
    }

    return _scaleGesture;
}

@end
