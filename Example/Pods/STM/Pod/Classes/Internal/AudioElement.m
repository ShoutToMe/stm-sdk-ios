//
//  AudioElement.m
//  ShoutToMeDev
//
//  Description:
//      This object represents an audio element used by the audio system
//
//  Created by Adam Harris on 3/16/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import "AudioElement.h"

static unsigned int nextID = 0;

@implementation AudioElement

- (id)init
{
    self = [super init];
    if (self)
    {
        self.id = nextID++;
        self.delegate = nil;
    }
    return self;
}

- (NSString *)description
{
    NSString *strDesc = [NSString stringWithFormat:@"AudioElement - id: %lu, type: %@",
                         self.id,
                         self.type == STMAudioElementType_Sound ? @"sound" : @"speech"
                         ];

    return strDesc;
}

- (NSUInteger)hash
{
    return self.id;
}

- (BOOL)isEqual:(id)other
{
    BOOL bEqual = NO;

    if ([other isKindOfClass:[AudioElement class]])
    {
        AudioElement *otherAudioElement = (AudioElement *)other;
        bEqual = (otherAudioElement.id == self.id);
    }

    return bEqual;
}

#pragma mark - Public Methods

#pragma mark - Misc Methods


@end