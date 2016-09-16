#import "UIView+Bouncy.h"
#import <pop/POP.h>

@implementation UIView (Bouncy)

// These matches Scott's exact tension / friction from his .js mocks
// change these if scott's values change
static const CGFloat kBouncyDynamicsTension = 1000;
static const CGFloat kBouncyDynamicsFriction = 20;

// This constant is needed so that, given Scott's exact tension / friction consts, it looks the same
// DO NOT CHANGE
static const CGFloat kBouncyDynamicsMass = 1.5;

// For Scott's algorithm for determining the scale of the view when pressed down
static const CGFloat kBouncyMinScale = 0.8;
static const CGFloat kBouncyMaxScale = 0.98;

static NSString *const kBouncyAnimationKey = @"BouncyAnimation";

- (void)cl_bouncy_pressIn
{
    [self.layer removeAllAnimations];

    POPBasicAnimation *animation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    animation.duration = 0.1;
    CGFloat scale = [self cl_bouncy_scaleFromWidth:self.bounds.size.width];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(scale, scale)];
    [self.layer pop_addAnimation:animation forKey:@"size"];
}

- (void)cl_bouncy_identity
{
    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];

    animation.dynamicsTension = kBouncyDynamicsTension;
    animation.dynamicsFriction = kBouncyDynamicsFriction;
    animation.dynamicsMass = kBouncyDynamicsMass;

    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(1.0, 1.0)];

    [self.layer pop_addAnimation:animation forKey:@"size"];
}

#pragma mark - Internal helpers
// This is the algorithm, via Scott, for the scale of the view
- (CGFloat)cl_bouncy_scaleFromWidth:(CGFloat)width
{
    CGFloat widthRatio = width / [UIScreen mainScreen].bounds.size.width;
    CGFloat scaleDiff = kBouncyMaxScale - kBouncyMinScale;
    return kBouncyMinScale + scaleDiff * widthRatio;
}

@end
