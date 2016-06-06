//
//  AudioElement.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 1/5/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

typedef enum eSTMAudioElementType
{
    STMAudioElementType_Sound,
    STMAudioElementType_Speech
} tSTMAudioElementType;

@interface AudioElement : NSObject

@property (nonatomic, assign)   unsigned long           id;
@property (nonatomic, assign)   tSTMAudioElementType    type;
@property (nonatomic, weak)     id                      delegate;
@property (nonatomic, strong)   AVAudioPlayer           *audioPlayer;
@property (nonatomic, strong)   AVSpeechSynthesizer     *speechSynth;
@property (nonatomic, strong)   id                      userData;

@end




