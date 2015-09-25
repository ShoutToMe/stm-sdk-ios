//
//  VoiceCmdView.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/12/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STM.h"
#import "STMRecorder.h"
#import "AudioSystem.h"

#define CONFIDENCE_THRESHOLD    .5

@protocol VoiceCmdViewDelegate;

typedef enum eVoiceCmdState
{
    VoiceCmdState_Stopped = 0,
    VoiceCmdState_Listening,
    VoiceCmdState_Processing
} tVoiceCmdState;

typedef enum eVoiceCmdSound
{
    VoiceCmdSound_None,
    VoiceCmdSound_Begin,
    VoiceCmdSound_Finalize,
    VoiceCmdSound_Abort
} tVoiceCmdSound;

typedef enum eVoiceCmdButton
{
    VoiceCmdButton_None,
    VoiceCmdButton_Yes,
    VoiceCmdButton_No
} tVoiceCmdButton;

@interface VoiceCmdResults : NSObject

//@property (nonatomic, assign) tVoiceCmdIntent   intent;
//@property (nonatomic, copy)   NSString          *strIntent;
@property (nonatomic, strong) NSDictionary      *dictEntities;
//@property (nonatomic, assign) CGFloat           confidence;
@property (nonatomic, strong) NSDictionary      *dictResults; // might be nil of no results
@property (nonatomic, strong) NSData            *dataAudio;
@property (nonatomic, copy)   NSString          *strText;
@property (nonatomic, assign) tVoiceCmdButton   buttonTouched;
@property (nonatomic, assign) BOOL              bUserClosed;
@property (nonatomic, assign) BOOL              bVoiceError;
@property (nonatomic, strong) NSError           *voiceError; // nil if no voice error
@property (nonatomic, assign) BOOL              bUserRequestedStopListening;
@property (nonatomic, assign) BOOL              bTimeout;

@end

@interface VoiceCmdView : UIView<STMRecorderDelegate, AudioSystemDelegate>

+ (VoiceCmdView *)CreateWithWidth:(CGFloat)width;
//+ (void)setIntentState:(tVoiceCmdIntentState)intentState;

@property (nonatomic, assign)   id<VoiceCmdViewDelegate>    delegate;
@property (nonatomic, readonly) tVoiceCmdState              state;
@property                       STMRecorder                 *stmRecorder;
@property (nonatomic, weak) UIViewController *viewController;

- (void)offsetY:(CGFloat)yOffset;
- (void)setTitleAndStartListening:(NSString *)strTitle;
- (void)speakTitleAndStartListening:(NSString *)strTitle;
- (NSString *)getCurrentTitle;
- (void)setTitle:(NSString *)strTitle;
- (void)setTitleTemp:(NSString *)strTitle;
- (void)startListening;
- (void)stopListening;
- (void)userRequestsStopListening;
- (void)completeWithSound:(tVoiceCmdSound)sound;
- (void)abort;
- (void)switchToYesNoMode;
- (void)stopRecording;


@end

@protocol VoiceCmdViewDelegate <NSObject>

@required

@optional

- (void)VoiceCmdView:(VoiceCmdView *)voiceCmdView newState:(tVoiceCmdState)state;
- (void)VoiceCmdView:(VoiceCmdView *)voiceCmdView completeWithResults:(VoiceCmdResults *)results;
- (void)VoiceCmdViewCloseButtonTouched:(VoiceCmdView *)voiceCmdView;

@end