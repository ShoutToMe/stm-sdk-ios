//
//  AudioSystem.m
//  ShoutToMeDev
//
//  Description:
//      This module provides the functionality for all audio so that audio can run in co-op with other apps
//
//  Created by Adam Harris on 3/16/15.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <AVFoundation/AVAudioPlayer.h>
#import "STM.h"
#import "Utils.h"
#import "Settings.h"
//#import "AudioSystem.h"
#import "AudioSystem.h"
#import "DL_URLServer.h"
#import "Server.h"

#define DEACTIVATE_DELAY_SECS               0.5

static BOOL bInitialized = NO;

__strong static AudioSystem *singleton = nil; // this will be the one and only object this static singleton class has

@interface AudioSystem () <AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate>
{
    BOOL                _bActive;
    NSInteger           _nHoldCount;
    tSTMAudioInputType  _typeInput;
    tSTMAudioOutputType _typeOutput;
}

@property (nonatomic, weak)     AVAudioSession  *session;
@property (nonatomic, strong)   NSMutableSet    *setElements;       // currently playing audio elements
@property (nonatomic, strong)   NSTimer         *updateTimer; // debug only

@end

@implementation AudioSystem

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        singleton = [[AudioSystem alloc] init];

		bInitialized = YES;
	}
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
		
		bInitialized = NO;
	}
}

// returns the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (AudioSystem *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.setElements = [[NSMutableSet alloc] init];
        self.session = [AVAudioSession sharedInstance];
        _typeInput = STMAudioInputType_None;
        _typeOutput = STMAudioOutputType_Normal;
        _bActive = NO;

        // this will be needed for the pause/unpause button on wired headset
        //[self activate:YES];
        //[self activate:NO];

        // create the update timer (debug usage)
        //self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateTimerFired:) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)dealloc
{

}

#pragma mark - Public Methods

- (void)holdActive:(BOOL)bHold
{
    if (bHold)
    {
        _nHoldCount++;

        if (!_bActive)
        {
            [self activate:YES];
        }
    }
    else
    {
        _nHoldCount--;
        [self performSelector:@selector(deactivateIfRequired) withObject:nil afterDelay:DEACTIVATE_DELAY_SECS];
    }
}

// speaks the given phrase
- (void)speak:(NSString *)strPhrase withDelegate:(id<AudioSystemDelegate>)delegate andUserData:(id)userData
{
    AudioElement *elem = [[AudioElement alloc] init];
    elem.type = STMAudioElementType_Speech;
    elem.speechSynth = [[AVSpeechSynthesizer alloc] init];
    elem.speechSynth.delegate = self;
    elem.delegate = delegate;
    elem.userData = userData;

    AVSpeechUtterance *utterance = [AVSpeechUtterance  speechUtteranceWithString:strPhrase];
    utterance.rate = AVSpeechUtteranceMaximumSpeechRate / 8;
    utterance.rate = 0.1000;
    utterance.volume = 1;

    [self addElement:elem];
    [self activate:YES];

    //NSLog(@"AudioSystem speaking: %@", strPhrase);

    [elem.speechSynth speakUtterance:utterance];
}

// plays the specified file from the bundle
- (void)playBundleFile:(NSString *)strFileAudio withDelegate:(id<AudioSystemDelegate>)delegate andUserData:(id)userData
{
    // Construct URL to sound file
    NSBundle *bundle = [NSBundle bundleForClass:STM.class];
//    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle]
//                              pathForResource:@"STM"
//                              ofType:@"bundle"]];
    NSString *path = [NSString stringWithFormat:@"%@/%@", [bundle resourcePath], strFileAudio];
    NSURL *soundUrl = [NSURL fileURLWithPath:path];
    

    NSData *dataAudio = [NSData dataWithContentsOfURL:soundUrl];
    
    [self playData:dataAudio withDelegate:delegate andUserData:userData];
}

// playes the specified audio data
- (void)playData:(NSData *)dataAudio withDelegate:(id<AudioSystemDelegate>)delegate andUserData:(id)userData
{
    AudioElement *elem = [[AudioElement alloc] init];
    elem.type = STMAudioElementType_Sound;
    elem.speechSynth = [[AVSpeechSynthesizer alloc] init];
    elem.speechSynth.delegate = self;
    elem.delegate = delegate;
    elem.userData = userData;

    // Create audio player object and initialize with URL to sound
    NSError *error;
    elem.audioPlayer = [[AVAudioPlayer alloc] initWithData:dataAudio error:&error];
    if (!elem.audioPlayer)
    {
        NSLog(@"AudioSystem Error: init with data - %@", [error localizedDescription]);
    }
    elem.audioPlayer.delegate = self;

    [self addElement:elem];
    [self activate:YES];

    //NSLog(@"AudioSystem playing...");

    [elem.audioPlayer play];
}

// stops all audio and speech for a given delegate
- (void)stopAudioAndSpeechFor:(id<AudioSystemDelegate>)delegate cancelCallback:(BOOL)bCancelCallback
{
    NSMutableSet *setStop = [[NSMutableSet alloc] init];

    // look for elements with this delegate
    for (AudioElement *curElem in self.setElements)
    {
        if (delegate == curElem.delegate)
        {
            [setStop addObject:curElem];
        }
    }

    // look through the stop elements
    for (AudioElement *curElem in setStop)
    {
        if (curElem.delegate == delegate)
        {
            if (bCancelCallback)
            {
                curElem.delegate = nil;
            }

            if (curElem.type == STMAudioElementType_Speech)
            {
                [curElem.speechSynth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            }
            else if (curElem.type == STMAudioElementType_Sound)
            {
                [curElem.audioPlayer stop];
                // stop does not call finish playing, so we need to do so
                [self audioPlayerDidFinishPlaying:curElem.audioPlayer successfully:YES];
            }
        }
    }
}

// returns YES if currently speaking
- (BOOL)isSpeaking
{
    BOOL bIsSpeaking = NO;

    for (AudioElement *curElem in self.setElements)
    {
        if (curElem.type == STMAudioElementType_Speech)
        {
            bIsSpeaking = YES;
            break;
        }
    }

    return bIsSpeaking;
}

// returns YES if currently playing a sound
- (BOOL)isPlayingSound
{
    BOOL bIsPlayingSound = NO;

    for (AudioElement *curElem in self.setElements)
    {
        if (curElem.type == STMAudioElementType_Sound)
        {
            bIsPlayingSound = YES;
            break;
        }
    }

    return bIsPlayingSound;
}

// returns YES if anything is being played or spoken
- (BOOL)isPlaying
{
    return ([self.setElements count] > 0);
}

// switches the input type
- (void)setInputType:(tSTMAudioInputType)type
{
    BOOL bChanged = (_typeInput != type);

    _typeInput = type;

    // if the input method changed and we are active
    if (bChanged && _bActive)
    {
        [self initSession];
    }
}

// switches the output type
- (void)setOutputType:(tSTMAudioOutputType)type
{
    _typeOutput = type;
}

#pragma mark - Misc Methods

// activates audio
- (void)activate:(BOOL)bActive
{
    [self activate:bActive force:NO];
}

// set it active or inactive, if force is set, then it is set or not set even if it is already set or not set
- (void)activate:(BOOL)bActive force:(BOOL)bForce
{
    BOOL    bSuccess;
    NSError *error;

    if (bActive)
    {
        if (!_bActive || bForce)
        {
            //NSLog(@"AudioSystem activating");

            // activate audio session
            [self initSession];
            bSuccess = [self.session setActive:YES error:&error];
            if (!bSuccess)
            {
                NSLog(@"AudioSystem Error: activate - %@", [error localizedDescription]);
            }
        }
    }
    else
    {
        //NSLog(@"AudioSystem deactivating");

        bSuccess = [self.session setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
        if (!bSuccess)
        {
            NSLog(@"AudioSystem Error: deactivate - %@", [error localizedDescription]);
        }
    }

    _bActive = bActive;
}

// initializes the session to record/play or play
- (void)initSessionRecord:(BOOL)bRecord
{
    AVAudioSessionCategoryOptions options = 0;

    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)
    {
        options |= AVAudioSessionCategoryOptionDuckOthers;
    }

    NSError *error;
    NSString *strCategory;

    if (bRecord)
    {
        //NSLog(@"setting category to record");
        strCategory = AVAudioSessionCategoryPlayAndRecord;
        options |= AVAudioSessionCategoryOptionDefaultToSpeaker;
        options |= AVAudioSessionCategoryOptionAllowBluetooth;
    }
    else
    {
        //NSLog(@"setting category to playback");
        strCategory = AVAudioSessionCategoryPlayback;
    }

    BOOL bSuccess = [self.session setCategory:strCategory withOptions:options error:&error];
    if (!bSuccess)
    {
        NSLog(@"AudioSystem Error: setCategory - %@", [error localizedDescription]);
    }
}

// initializes the session
- (void)initSession
{
    BOOL bRecordSession;

    // if they want to record or want to playback in HFP
    if ((_typeInput != STMAudioInputType_None || _typeOutput == STMAudioOutputType_BluetoothHFP))
    {
        bRecordSession = YES;
    }
    else
    {
        bRecordSession = NO;
    }

    // initialize the session
    [self initSessionRecord:bRecordSession];

    // if they wanted to output to bluetooth but weren't recording, check now see if they actually have the device
    // because if they don't, we need to switch back to 'play'
    if ((_typeOutput == STMAudioOutputType_BluetoothHFP) && (_typeInput == STMAudioInputType_None))
    {
        // if they don't have HFP
        if (![self hasHFP])
        {
            // back to playback
            bRecordSession = NO;
            [self initSessionRecord:bRecordSession];
        }
    }

    // if we are in record mode
    if (bRecordSession)
    {
        // set the mic we want to use
        [self initInput];
    }

    //NSLog(@"output sources: %@", [self.session outputDataSources]);
    //NSLog(@"availableInputs: %@", [self.session availableInputs]);
}

// can only be called on a session that has had setCategory called
- (BOOL)hasHFP
{
    BOOL bHas = NO;

    // check if we have the device
    NSArray *arrayInputs = [self.session availableInputs];
    for (AVAudioSessionPortDescription *port in arrayInputs)
    {
        if ([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP])
        {
            bHas = YES;
            break;
        }
    }

    return bHas;
}

// returns YES if the active audio is being held (i.e., don't release after audio has completed)
- (BOOL)holdIsActive
{
    BOOL bIsActive = NO;

    if (_nHoldCount > 0)
    {
        bIsActive = YES;
    }
    else if (_nHoldCount < 0)
    {
        _nHoldCount = 0;
    }

    return bIsActive;
}

// deactives audio if needed
- (void)deactivateIfRequired
{
    if (([self.setElements count] == 0) && ![self holdIsActive] && _bActive)
    {
        [self activate:NO];
    }
}

// announces the starting or stopping of all audio if needed
- (void)announceIfNeeded
{
    NSUInteger nElems = [self.setElements count];

    // if we have no elements then audio must have stopped
    if (nElems == 0)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_AUDIO_SYSTEM_STOPPED_PLAYING object:self userInfo:nil];
    }
    else if (nElems == 1)
    {
        // a single element must have been added
        [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_AUDIO_SYSTEM_STARTED_PLAYING object:self userInfo:nil];
    }
}

// handles completion of speech
- (void)speechComplete:(AVSpeechSynthesizer *)synthesizer
{
    AudioElement *elem = nil;

    // find the element associated with this synth
    for (AudioElement *curElem in self.setElements)
    {
        if (curElem.speechSynth == synthesizer)
        {
            elem = curElem;
            break;
        }
    }

    if (elem)
    {
        // inform the delegate
        if (elem.delegate)
        {
            if ([elem.delegate respondsToSelector:@selector(AudioSystemElementComplete:)])
            {
                [elem.delegate AudioSystemElementComplete:elem];
            }
        }

        // remove it from the set
        [self removeElement:elem];
    }
}

// handles completion of audio playing
- (void)audioComplete:(AVAudioPlayer *)player
{
    AudioElement *elem = nil;

    // find the element associated with this synth
    for (AudioElement *curElem in self.setElements)
    {
        if (curElem.audioPlayer == player)
        {
            elem = curElem;
            break;
        }
    }

    if (elem)
    {
        // inform the delegate
        if (elem.delegate)
        {
            if ([elem.delegate respondsToSelector:@selector(AudioSystemElementComplete:)])
            {
                [elem.delegate AudioSystemElementComplete:elem];
            }
        }

        // remove it from the set
        [self removeElement:elem];
    }
}

// adds an audio element to the set of playing audio elements
- (void)addElement:(AudioElement *)elem
{
    if (elem)
    {
        [self.setElements addObject:elem];
        [self announceIfNeeded];
    }
}

// removes an audio element from the list of playing audio elements
- (void)removeElement:(AudioElement *)elem
{
    if (elem)
    {
        [self.setElements removeObject:elem];

        [self announceIfNeeded];
    }

    [self performSelector:@selector(deactivateIfRequired) withObject:nil afterDelay:DEACTIVATE_DELAY_SECS];
}

// can only be called on session that has been initialized with setCategory
- (void)initInput
{
    AVAudioSessionPortDescription *builtInMicPort = nil;
    AVAudioSessionPortDescription *wiredMicPort = nil;
    AVAudioSessionPortDescription *bluetoothMicPort = nil;

    NSArray *arrayInputs = [self.session availableInputs];
    for (AVAudioSessionPortDescription *port in arrayInputs)
    {
        //NSLog(@"port: %@", port.portType);

        if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic])
        {
            builtInMicPort = port;
        }
        else if ([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP])
        {
            bluetoothMicPort = port;
        }
        else if ([port.portType isEqualToString:AVAudioSessionPortHeadsetMic])
        {
            wiredMicPort = port;
        }

        /*
         if ([port.portType isEqualToString:AVAudioSessionPortLineIn]) NSLog(@"const: %@",AVAudioSessionPortLineIn);
         if ([port.portType isEqualToString:AVAudioSessionPortBuiltInMic]) NSLog(@"const: %@",AVAudioSessionPortBuiltInMic);
         if ([port.portType isEqualToString:AVAudioSessionPortHeadsetMic]) NSLog(@"const: %@",AVAudioSessionPortHeadsetMic);
         if ([port.portType isEqualToString:AVAudioSessionPortLineOut]) NSLog(@"const: %@",AVAudioSessionPortLineOut);
         if ([port.portType isEqualToString:AVAudioSessionPortHeadphones]) NSLog(@"const: %@",AVAudioSessionPortHeadphones);
         if ([port.portType isEqualToString:AVAudioSessionPortBluetoothA2DP]) NSLog(@"const: %@",AVAudioSessionPortBluetoothA2DP);
         if ([port.portType isEqualToString:AVAudioSessionPortBuiltInReceiver]) NSLog(@"const: %@",AVAudioSessionPortBuiltInReceiver);
         if ([port.portType isEqualToString:AVAudioSessionPortBuiltInSpeaker]) NSLog(@"const: %@",AVAudioSessionPortBuiltInSpeaker);
         if ([port.portType isEqualToString:AVAudioSessionPortHDMI]) NSLog(@"const: %@",AVAudioSessionPortHDMI);
         if ([port.portType isEqualToString:AVAudioSessionPortAirPlay]) NSLog(@"const: %@",AVAudioSessionPortAirPlay);
         if ([port.portType isEqualToString:AVAudioSessionPortBluetoothLE]) NSLog(@"const: %@",AVAudioSessionPortBluetoothLE);
         if ([port.portType isEqualToString:AVAudioSessionPortBluetoothHFP]) NSLog(@"const: %@",AVAudioSessionPortBluetoothHFP);
         if ([port.portType isEqualToString:AVAudioSessionPortUSBAudio]) NSLog(@"const: %@",AVAudioSessionPortUSBAudio);
         if ([port.portType isEqualToString:AVAudioSessionPortCarAudio]) NSLog(@"const: %@",AVAudioSessionPortCarAudio);
         */
    }

    AVAudioSessionPortDescription *builtInToUse = builtInMicPort;
    if (wiredMicPort != nil)
    {
        builtInToUse = wiredMicPort;
    }

    AVAudioSessionPortDescription *bluetoothToUse = builtInToUse;
    if (bluetoothMicPort != nil)
    {
        bluetoothToUse = bluetoothMicPort;
    }

    AVAudioSessionPortDescription *finalToUse;
    if ((_typeInput == STMAudioInputType_BluetoothHFP) || (_typeOutput == STMAudioOutputType_BluetoothHFP))
    {
        //NSLog(@"using bluetooth mic");
        finalToUse = bluetoothToUse;
    }
    else
    {
        //NSLog(@"using built-in mic");
        finalToUse = builtInToUse;
    }

    NSError *error = nil;
    if (![self.session setPreferredInput:finalToUse error:&error])
    {
        NSLog(@"AudioSystem : setPreferredInput failed");
    }
}

#pragma mark - AVAudioPlayer Delegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //NSLog(@"finished playing audio");

    [self audioComplete:player];
}

- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player
{
    //NSLog(@"audio player end interruption");

    [player play];
}

#pragma mark - AVSpeechSynthesizer Delegates

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    //NSLog(@"AudioSystem finished speaking: %@", utterance.speechString);

    [self speechComplete:synthesizer];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    //NSLog(@"AudioSystem cancel speaking: %@", utterance.speechString);

    [self speechComplete:synthesizer];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance
{
    //NSLog(@"AudioSystem didPause speaking: %@", utterance.speechString);

    [synthesizer continueSpeaking];
}


#pragma mark - Timer

- (void)updateTimerFired:(NSTimer *)timer
{
    NSLog(@"Current route: %@", [self.session currentRoute]);
}

@end
