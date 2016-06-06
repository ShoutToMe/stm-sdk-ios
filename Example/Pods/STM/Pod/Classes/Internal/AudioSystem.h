//
//  AudioSystem.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 3/16/15.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AudioElement.h"

#define STMAudio_ShoutSend          @"sent.caf"
#define STMAudio_ShoutUndo          @"undo.caf"

typedef enum eSTMAudioInputType
{
    STMAudioInputType_None = 0,
    STMAudioInputType_BuiltInMic,
    STMAudioInputType_BluetoothHFP // if not available, will use built-in mic
} tSTMAudioInputType;

typedef enum eSTMAudioOutputType
{
    STMAudioOutputType_Normal = 0,
    STMAudioOutputType_BluetoothHFP
} tSTMAudioOutputType;

@protocol AudioSystemDelegate <NSObject>

@optional

- (void)AudioSystemElementComplete:(AudioElement *)audioElement;

@end

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all


@interface AudioSystem : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (AudioSystem *)controller;

- (void)holdActive:(BOOL)bHold;
- (void)speak:(NSString *)strPhrase withDelegate:(id<AudioSystemDelegate>)delegate andUserData:(id)userData;
- (void)playBundleFile:(NSString *)strFileAudio withDelegate:(id<AudioSystemDelegate>)delegate andUserData:(id)userData;
- (void)playData:(NSData *)dataAudio withDelegate:(id<AudioSystemDelegate>)delegate andUserData:(id)userData;
- (void)stopAudioAndSpeechFor:(id<AudioSystemDelegate>)delegate cancelCallback:(BOOL)bCancelCallback;
- (BOOL)isSpeaking;
- (BOOL)isPlayingSound;
- (BOOL)isPlaying;
- (void)setInputType:(tSTMAudioInputType)type;
- (void)setOutputType:(tSTMAudioOutputType)type;

@end

