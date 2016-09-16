#import "BouncyButton.h"
#import "UIView+Bouncy.h"

@implementation BouncyButton

#pragma mark - initialization

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    highlighted ? [self cl_bouncy_pressIn] : [self cl_bouncy_identity];
}

@end
