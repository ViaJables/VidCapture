#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIView (Bouncy)

- (void)cl_bouncy_pressIn;

- (void)cl_bouncy_identity; // bounces the view's layer to CATransform3DIdentity

@end
