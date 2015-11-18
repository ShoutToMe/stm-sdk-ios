//
//  VoiceCmdView.m
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/12/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
//#import <Wit/Wit.h>
#import "VoiceCmdView.h"
#import "GraphView.h"
#import "StandardButton.h"
#import "STM.h"
#import <architecture/byte_order.h>

#define MIN_AUDIO_LEN_AFTER_ERR     40000 // if there is a wit error, what is the min length of audio data require to report error

#define GRAPH_LINE_WIDTH            2.0
#define GRAPH_LINE_SPACING          1.0
#define GRAPH_LINE_COLOR            [UIColor colorWithRed:0.0/255.0 green:126.0/255.0 blue:230.0/255.0 alpha:1.0]
#define GRAPH_MIN_VALUE             -42.0
#define GRAPH_MAX_VALUE             1.5

#define MAX_LISTEN_TIME_SECS        15.0
#define MAX_SILENCE_WAIT_TIME_SECS  2.0

#define BUTTONS_CORNER_RADIUS       3
#define BUTTONS_DIST_FROM_BOTTOM    120.0
#define BUTTONS_SPACE_AFTER_GRAPH   20.0   // how much space is required after the graph before the buttons

//static __unused NSString* const kWitNotificationAudioPowerChanged = @"WITAudioPowerChanged";

typedef enum eVoiceCmdAfterSound
{
    VoiceCmdAfterSound_None,
    VoiceCmdAfterSound_Listen,
    VoiceCmdAfterSound_Complete
} tVoiceCmdAfterSound;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation VoiceCmdResults

- (id)init
{
    self = [super init];
    if (self)
    {
        //self.intent = VoiceCmdIntent_unknown;
        //self.confidence = 0.0;
        self.dictResults = nil;
        self.dataAudio = nil;
        self.strText = @"";
        self.buttonTouched = VoiceCmdButton_None;
        self.bUserClosed = NO;
        self.voiceError = nil;
        self.bUserRequestedStopListening = NO;
        self.bTimeout = NO;
    }
    return self;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface VoiceCmdView () <GraphViewDelegate, AudioSystemDelegate>
{
    BOOL                _bInitialized;
    tVoiceCmdAfterSound _afterSound;
    BOOL                _bAborting;
    BOOL                _bYesNoMode;
}

@property (weak, nonatomic) IBOutlet    UIView                      *viewMain;
@property (weak, nonatomic) IBOutlet    GraphView                   *viewGraph;
@property (weak, nonatomic) IBOutlet    UIActivityIndicatorView     *indicator;
@property (weak, nonatomic) IBOutlet    UILabel                     *labelContextSpecificText;
@property (weak, nonatomic) IBOutlet    UIView                      *viewButtonsYesNo;
@property (weak, nonatomic) IBOutlet    UIView                      *viewButtonsCancel;
@property (weak, nonatomic) IBOutlet    UIView                      *viewButtonsDone;

@property (nonatomic, assign)           BOOL                        bComplete;
@property (nonatomic, assign)           BOOL                        bSilence;
@property (nonatomic, assign)           CGRect                      frameGraphOrig;
@property (nonatomic, strong)           NSTimer                     *timer;
@property (nonatomic, strong)           NSTimer                     *silenceTimer;
@property (nonatomic, strong)           NSMutableData               *dataAudio;
@property (nonatomic, strong)           NSMutableData               *dataTempAudio;
@property (nonatomic, strong)           VoiceCmdResults             *results;
@property (nonatomic, copy)             NSString                    *strListeningMsg;

@end

@implementation VoiceCmdView

#pragma mark - Static Methods


+ (VoiceCmdView *)CreateWithWidth:(CGFloat)width
{
    VoiceCmdView *vcv;
    
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle]
                                                 pathForResource:@"STM"
                                                 ofType:@"bundle"]];
    
//    NSBundle *bundle = [NSBundle bundleForClass:STM.class];

    vcv = [[bundle loadNibNamed:@"VoiceCmdView" owner:nil options:nil] objectAtIndex:0];
    CGRect frame = vcv.frame;
    frame.origin.x = 0;
    frame.origin.y = 0;
    frame.size.width = width;
    vcv.frame = frame;

    return vcv;
}


//+ (void)setIntentState:(tVoiceCmdIntentState)intentState
//{
//    if ([[STM voiceCmd] isReady])
//    {
//        [[STM voiceCmd] setIntentState:intentState];
//    }
//}

#pragma mark - UIView Methods

- (id)init
{
    self = [super init];
    if (self)
    {
        [self initInternal];
    }
    return self;
}

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

- (void)dealloc
{
    //remove all notifications associated with self
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.timer invalidate];
    self.timer = nil;
    
}

#pragma mark - Accessors

// sets the current state
- (void)setState:(tVoiceCmdState)state
{
    if (_state != state)
    {
        _state = state;

        if ([self.delegate respondsToSelector:@selector(VoiceCmdView:newState:)])
        {
            [self.delegate VoiceCmdView:self newState:state];
        }
    }
}

// sets whether the voice comand is complete
- (void)setBComplete:(BOOL)bComplete
{
    _bComplete = bComplete;
    //NSLog(@"Setting bComplete to: %@", (bComplete ? @"YES" : @"NO"));
}

#pragma mark - Action Methods

- (IBAction)buttonCloseTouched:(id)sender
{
    [self prepareResults];
    self.results.bUserClosed = YES;
    [[STM audioSystem] stopAudioAndSpeechFor:self cancelCallback:YES];
    [self stopSpeaking];
    if ([self.delegate respondsToSelector:@selector(VoiceCmdViewCloseButtonTouched:)])
    {
        [self.delegate VoiceCmdViewCloseButtonTouched:self];
    }

    [self completeWithSound:VoiceCmdSound_Abort];
}

- (IBAction)buttonYesTouched:(id)sender
{
    self.results.buttonTouched = VoiceCmdButton_Yes;
    //self.results.intent = VoiceCmdIntent_yes;
    //self.results.confidence = 1.0;
    if (self.state == VoiceCmdState_Stopped)
    {
        [self stopSpeaking];
        [self complete];
    }
    else
    {
        [self stopListening];
    }
}

- (IBAction)buttonNoTouched:(id)sender
{
    self.results.buttonTouched = VoiceCmdButton_No;
    //self.results.intent = VoiceCmdIntent_no;
    //self.results.confidence = 1.0;
    if (self.state == VoiceCmdState_Stopped)
    {
        [self stopSpeaking];
        [self complete];
    }
    else
    {
        [self stopListening];
    }
}

- (IBAction)buttonDoneTouched:(id)sender
{
    [self userRequestsStopListening];
}

#pragma mark - Public Methods

- (void)offsetY:(CGFloat)yOffset
{
    CGRect frame = self.viewMain.frame;
    frame.origin.y += yOffset;
    self.viewMain.frame = frame;
}

- (void)setTitleAndStartListening:(NSString *)strTitle
{
    [self prepareResults];
    self.bComplete = NO;
    [self setTitle:strTitle];
    [self startListening];
}

- (void)speakTitleAndStartListening:(NSString *)strTitle
{
    [self prepareResults];
    self.bComplete = NO;
    if (strTitle)
    {
        [self setTitle:strTitle];
    }
    [self speak:self.strListeningMsg];
}

- (NSString *)getCurrentTitle
{
    return self.strListeningMsg;
}

- (void)setTitle:(NSString *)strTitle
{
    self.strListeningMsg = strTitle;
    self.labelContextSpecificText.text = strTitle;
}

- (void)setTitleTemp:(NSString *)strTitle
{
    self.labelContextSpecificText.text = strTitle;
}

- (void)startListening
{
    if ((!_bComplete) && (self.state == VoiceCmdState_Stopped))
    {
        [self prepareResults];
        [self playSound:VoiceCmdSound_Begin withCommandAfter:VoiceCmdAfterSound_Listen];
    }
}

- (void)startListeningWithNoSoundPrompt
{
    if ((!_bComplete) && (self.state == VoiceCmdState_Stopped))
    {
        [self prepareResults];
        self.dataAudio = [[NSMutableData alloc] init];
        self.dataTempAudio = [[NSMutableData alloc] init];
        self.state = VoiceCmdState_Listening;
        [self.viewGraph clear];
        [self.stmRecorder start];

        [self updateDisplay];
    }
}

- (void)stopListening
{
    if ((!_bComplete) && (self.state == VoiceCmdState_Listening))
    {
        self.state = VoiceCmdState_Stopped;
        [self.timer invalidate];
        self.timer = nil;
        if ([self.stmRecorder isRecording]){
            [self stopRecording];
        }
        
        [self updateDisplay];
    }
}

- (void)userRequestsStopListening
{
    if (!self.viewButtonsDone.hidden)
    {
        self.results.bUserRequestedStopListening = YES;
        [self stopListening];
    }
}

- (void)completeWithSound:(tVoiceCmdSound)sound
{
    [self playSound:sound withCommandAfter:VoiceCmdAfterSound_Complete];
}

- (void)abort
{
    _bAborting = YES;
    [self stopSpeaking];
    [self stopListening];
}

- (void)switchToYesNoMode
{
    _bYesNoMode = YES;
    self.viewButtonsYesNo.hidden = NO;
    self.viewButtonsDone.hidden = YES;
    self.viewButtonsCancel.hidden = YES;
}

#pragma mark - Misc Methods

- (void)initInternal
{
    if (!_bInitialized)
    {
        self.strListeningMsg = @"Listening...";
        self.viewButtonsCancel.hidden = YES;
        self.viewButtonsYesNo.hidden = YES;
        self.viewButtonsCancel.hidden = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(powerChanged:) name:STM_NOTIFICATION_AUDIO_POWER_CHANGED object:nil];

        self.results = [[VoiceCmdResults alloc] init];

        self.viewGraph.delegate = self;
        self.viewGraph.lineWidth = GRAPH_LINE_WIDTH;
        self.viewGraph.lineSpacing = GRAPH_LINE_SPACING;
        self.viewGraph.minValue = GRAPH_MIN_VALUE;
        self.viewGraph.maxValue = GRAPH_MAX_VALUE;
        self.viewGraph.lineColor = GRAPH_LINE_COLOR;

        self.indicator.hidden = YES;
        self.viewGraph.hidden = YES;

        self.bComplete = NO;
        self.bSilence = NO;
        
        self.stmRecorder =  [[STMRecorder alloc] init];
        self.stmRecorder.delegate = self;
        [self.stmRecorder enabledVad];

        _bInitialized = YES;
    }
}

- (void)prepareResults
{
    if (!self.results)
    {
        self.results = [[VoiceCmdResults alloc] init];
    }
}

- (void)updateDisplay
{
    switch (self.state)
    {
        case VoiceCmdState_Stopped:
            [self.viewGraph clear];
            self.labelContextSpecificText.text = @"";//NSLocalizedString(@"Speaking...", nil);
            self.indicator.hidden = YES;
            self.viewGraph.hidden = YES;
            break;

        case VoiceCmdState_Listening:
            self.indicator.hidden = YES;
            self.viewGraph.hidden = NO;
            self.labelContextSpecificText.text = self.strListeningMsg;
            self.viewButtonsCancel.hidden = YES;
            self.viewButtonsYesNo.hidden = !_bYesNoMode;
            self.viewButtonsDone.hidden = _bYesNoMode;
            break;

        case VoiceCmdState_Processing:
            self.labelContextSpecificText.text = NSLocalizedString(@"Thinking...", nil);
            self.viewButtonsCancel.hidden = NO;
            self.viewButtonsYesNo.hidden = YES;
            self.viewButtonsDone.hidden = YES;
            self.viewGraph.hidden = YES;
            self.indicator.hidden = NO;
            break;

        default:
            break;
    }
}

- (void)playSound:(tVoiceCmdSound)sound withCommandAfter:(tVoiceCmdAfterSound)command
{
    if (_bAborting)
    {
        return;
    }

    _afterSound = command;

    NSString *strName = nil;

    switch (sound)
    {
        case VoiceCmdSound_Abort:
            strName = @"abort.caf";
            break;

        case VoiceCmdSound_Begin:
            strName = @"listen.caf";
            break;

        case VoiceCmdSound_Finalize:
            strName = @"finish.caf";
            break;

        default:
            break;
    }

    if (strName)
    {
        [[STM audioSystem] playBundleFile:strName withDelegate:self andUserData:nil];
    }
}

- (void)speak:(NSString *)strPhrase
{
    [self stopSpeaking];

    [[STM audioSystem] speak:strPhrase withDelegate:self andUserData:nil];
}

- (void)stopSpeaking
{
    [[STM audioSystem] stopAudioAndSpeechFor:self cancelCallback:YES];
}

// called when voice command is complete
- (void)complete
{
    self.bComplete = YES;
    [self.timer invalidate];
    self.timer = nil;
    
    [self stopRecording];

    self.results.dataAudio = self.dataAudio;
    if ([self.delegate respondsToSelector:@selector(VoiceCmdView:completeWithResults:)])
    {
        [self.delegate VoiceCmdView:self completeWithResults:self.results];
    }
    self.results = nil;
}

#pragma mark - Audio Queue Service Methods

- (void)stopRecording
{
    [self.stmRecorder stop];
    
    if (_bAborting)
    {
        return;
    }
    
    if (!_bComplete)
    {
        tVoiceCmdSound sound = VoiceCmdSound_None;
        tVoiceCmdAfterSound cmdAfterSound = VoiceCmdAfterSound_None;
        
        if (true)
        {
            if (self.results.buttonTouched != VoiceCmdButton_None)
            {
                cmdAfterSound = VoiceCmdAfterSound_Complete;
                
                if (self.results.buttonTouched == VoiceCmdButton_No)
                {
                    sound = VoiceCmdSound_Abort;
                }
                else
                {
                    sound = VoiceCmdSound_Finalize;
                }
            } else
            {
                
                cmdAfterSound = VoiceCmdAfterSound_Complete;
                sound = VoiceCmdSound_Finalize;
            }
            
            self.state = VoiceCmdState_Stopped;
            [self updateDisplay];
            
        } else
        {
            sound = VoiceCmdSound_Abort;
            cmdAfterSound = VoiceCmdAfterSound_Complete;
            
        }
        [self playSound:sound withCommandAfter:cmdAfterSound];
    }
}

#pragma mark - Timer notification

// used to detect timeout
- (void)timerFired
{
    if (!_bComplete)
    {
        self.results.bTimeout = YES;
        [self stopListening];
    }
}

- (void)silenceTimerFired
{
    [self stopListening];
}

#pragma mark - STMRecorder Delegates

-(void)recorderDetectedSpeech
{
    [self.silenceTimer invalidate];
    self.bSilence = NO;
    if ([self.dataTempAudio length] > 0)
    {
        [self.dataAudio appendData:self.dataTempAudio];
    }

    
}

-(void)recorderStarted
{
    if (!_bComplete)
    {
        [self.viewGraph clear];
        self.timer = [NSTimer scheduledTimerWithTimeInterval:MAX_LISTEN_TIME_SECS target:self selector:@selector(timerFired) userInfo:nil repeats:NO];
        //NSLog(@"%s", __FUNCTION__);
    }

}

-(void)recorderVadStoppedTalking
{
    self.bSilence = YES;
    self.silenceTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_SILENCE_WAIT_TIME_SECS target:self selector:@selector(silenceTimerFired) userInfo:nil repeats:NO];
}

-(void)recorderGotChunk:(NSData*)chunk
{
    if (self.bSilence) {
        [self.dataTempAudio appendData:chunk];
    } else {
        [self.dataAudio appendData:chunk];
    }

}

-(void)stop
{
    
}

-(void)powerChanged:(NSNotification *)notification
{
    if (!_bComplete)
    {
        static CGFloat min = 4000.0, max = -4000.0;
        
        NSNumber *power = (NSNumber *)notification.object;
        
        CGFloat curPower = [power floatValue];
        
        if (curPower < min || curPower > max)
        {
            min = fmin(min, curPower);
            max = fmax(max, curPower);
            
            //NSLog(@"power: min = %f, max = %f", min, max);
        }
        
        if (self.state == VoiceCmdState_Listening)
        {
            [self.viewGraph addNumber:power];
        }
        
        //NSLog(@"%f", [power floatValue]);
    }
}

#pragma mark - AudioSystem Delegates

- (void)AudioSystemElementComplete:(AudioElement *)audioElement
{
    if (audioElement.type == STMAudioElementType_Speech)
    {
        [self performSelector:@selector(startListening) withObject:nil afterDelay:0.0];
    }
    else if (audioElement.type == STMAudioElementType_Sound)
    {
        switch (_afterSound)
        {
            case VoiceCmdAfterSound_Listen:
                NSLog(@"Category: %@", [[AVAudioSession sharedInstance] category]);
                [self performSelector:@selector(startListeningWithNoSoundPrompt) withObject:nil afterDelay:0.1];
                _afterSound = VoiceCmdAfterSound_None;
                break;

            case VoiceCmdAfterSound_Complete:
                [self performSelector:@selector(complete) withObject:nil afterDelay:0.1];
                _afterSound = VoiceCmdAfterSound_None;
                break;
                
            default:
                break;
        }
    }
}

@end
