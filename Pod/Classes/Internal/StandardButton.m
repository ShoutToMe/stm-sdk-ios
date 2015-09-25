//
//  StandardButton.m
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/12/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "StandardButton.h"

@interface StandardButton ()
{
    BOOL _bInitialized;
}

@end

@implementation StandardButton

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
	{
        [self initInternal];
    }
    return self;
}

- (void)awakeFromNib
{
	[self initInternal];
}

#pragma mark - Misc Methods

- (void)initInternal
{
    if (!_bInitialized)
    {
        self.backgroundColor = STANDARD_BUTTON_COLOR;
        [self setTitleColor:STANDARD_BUTTON_TEXT_COLOR forState:UIControlStateNormal];
        self.layer.borderColor = STANDARD_BUTTON_BORDER_COLOR.CGColor;
        self.layer.borderWidth = STANDARD_BUTTON_BORDER_WIDTH;
        self.layer.cornerRadius = STANDARD_BUTTON_CORNER_RADIUS;
        self.clipsToBounds = YES;
        [self.titleLabel setFont:[UIFont boldSystemFontOfSize:STANDARD_BUTTON_FONT_SIZE]];

        _bInitialized = YES;
    }
}

@end
