//
//  RoundedButton.m
//  ShoutToMeDev
//
//  Created by Adam Harris on 1/16/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "RoundedButton.h"

@interface RoundedButton ()
{
    BOOL _bInitialized;
}

@end

@implementation RoundedButton

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
        self.layer.cornerRadius = ROUND_BUTTON_CORNER_RADIUS;
        self.clipsToBounds = YES;


        _bInitialized = YES;
    }
}

@end
