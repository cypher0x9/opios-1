/*
 
 Copyright (c) 2013, SMB Phone Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those
 of the authors and should not be interpreted as representing official policies,
 either expressed or implied, of the FreeBSD Project.
 
 */

#import "UIBadgeView.h"

@implementation UIBadgeView

@synthesize badgeText = _badgeText;
@synthesize badgeBackgroundColors = _badgeBackgroundColors;

-(void)setBadgeHidden:(BOOL)hidden
{
    _isHidden = hidden;
    [self setNeedsDisplay];
}

-(void)setDefaults
{
    // set defaults
    _isHidden = NO;
    
    //_badgeBackgroundColor = [[UIColor colorWithPatternImage:[Hookflash_ThemeManager imageNamed:ki_iPhone_badge]] retain];
    
    self.backgroundColor = [UIColor clearColor];
    self.layer.masksToBounds = YES;
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setDefaults];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{

    if(!_isHidden && _badgeText)
    {
        // draw badge
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
        
        CGSize badgeTextSize = [_badgeText sizeWithFont:_bagdeFont];
        CGRect bounds = CGRectMake(0 , 0, badgeTextSize.width + 14 , 18);
        float radius = rect.size.height/2;
        
        
        // create rounded rect
        CGMutablePathRef thePath = CGPathCreateMutable();
        CGPathMoveToPoint(thePath, NULL, CGRectGetMinX(bounds) + radius, CGRectGetMinY(bounds));
        CGPathAddArc(thePath, NULL, CGRectGetMaxX(bounds) - radius, CGRectGetMinY(bounds) + radius, radius, 3 * M_PI / 2, 0, 0);
        CGPathAddArc(thePath, NULL, CGRectGetMaxX(bounds) - radius, CGRectGetMaxY(bounds) - radius, radius, 0, M_PI / 2, 0);
        CGPathAddArc(thePath, NULL, CGRectGetMinX(bounds) + radius, CGRectGetMaxY(bounds) - radius, radius, M_PI / 2, M_PI, 0);
        CGPathAddArc(thePath, NULL, CGRectGetMinX(bounds) + radius, CGRectGetMinY(bounds) + radius, radius, M_PI, 3 * M_PI / 2, 0);	 
        CGPathCloseSubpath(thePath);        
        
        CGContextAddPath(context, thePath);

        if(_badgeBackgroundColors)
        {
            // add gradient
            
            CGContextSaveGState(context);
            CGContextClip(context);
            CGGradientRef gradient = CGGradientCreateWithColors(colorspace, (CFArrayRef)_badgeBackgroundColors, NULL);
            CGPoint startPoint = bounds.origin;
            CGPoint endPoint = CGPointMake(bounds.origin.x, bounds.origin.y + bounds.size.height);
            CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
            
            CGGradientRelease(gradient);
        }
        else
        {
            CGContextSetFillColorWithColor(context,[_badgeBackgroundColor CGColor]);
            CGContextDrawPath(context, kCGPathFill);   
            
            CGContextSaveGState(context);
            CGContextClip(context);
        }

        
        CGContextRestoreGState(context);
        
        CGPathRelease(thePath);
        CGColorSpaceRelease(colorspace);
        
        
        // draw badge text
        CGContextSetFillColorWithColor(context, _badgeTextColor.CGColor);
        bounds.origin.x = (bounds.size.width - badgeTextSize.width) / 2 + 0.5;
        bounds.origin.y = (bounds.size.height - _bagdeTextSize) / 2 - 1;
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        [_badgeText drawInRect:bounds withFont:_bagdeFont];
        
    }
}

@end
