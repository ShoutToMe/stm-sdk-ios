//
//  STMRecordingOverlayViewController.m
//  Pods
//
//  Created by Tyler Clemens on 9/14/15.
//
//

#import "STMRecordingOverlayViewController.h"
#import "SendShout.h"
#import "AppUtils.h"

#define SHOUT_SENT_SOUND                            @"sent.caf"
#define MIN_AUDIO_LEN_AFTER_ERR     40000

typedef enum eAfterAudioCmd
{
    AfterAudioCmd_None = 0,
    AfterAudioCmd_SpeakSent
} tAfterAudioCmd;

@interface STMRecordingOverlayViewController () <VoiceCmdViewDelegate, SendShoutDelegate>

@property (nonatomic, strong)   VoiceCmdView            *voiceCmdView;
@property (nonatomic, strong)   VoiceCmdResults         *voiceCmdResults;
@property (nonatomic, strong)   UIActivityIndicatorView *indicator;
@property (weak, nonatomic)     IBOutlet UIView         *viewBusy;
@property (nonatomic)           BOOL                    bDismiss;
@property NSString *tags;
@property NSString *topic;

@end

@implementation STMRecordingOverlayViewController

- (id)initWithTags:(NSString *)tags andTopic:(NSString *)topic {
    self = [super init];
    if (self) {
        self.tags = [tags copy];
        self.topic = [topic copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                self.indicator.center = self.voiceCmdView.center;
                [self.voiceCmdView addSubview:self.indicator];
                
                if (self.voiceCmdView == nil)
                {
                    // hold the audio as active for this app for the entire time the view is up
                    [[STM audioSystem] setInputType:STMAudioInputType_BluetoothHFP];
                    [[STM audioSystem] holdActive:YES];
                    self.voiceCmdView = [VoiceCmdView CreateWithWidth:self.view.bounds.size.width];
                    if (self.MaxListeningSeconds) {
                        self.voiceCmdView.MaxListeningSeconds = self.MaxListeningSeconds;
                    }
                    [self.voiceCmdView setTitle:@""];
                    self.voiceCmdView.delegate = self;
                    [self.view addSubview:self.voiceCmdView];
                    [self.voiceCmdView setTitleAndStartListening:@"Listening..."];
                }
            } else {
                UIAlertView *alert = [[UIAlertView alloc]
                                      initWithTitle:@"Mic Permissions"
                                      message:@"Mic permissions are required."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alert show];
                [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
                if ([self.delegate respondsToSelector:@selector(overlayClosed:)]) {
                    [self.delegate overlayClosed:YES];
                }
            }
        }];
    }
    
}

- (void)sendShout:(NSData *)dataAudio
{
    [[STM audioSystem] holdActive:YES];
    
    [self showBusy:YES];
    
    [[STM sendShout] sendData:dataAudio text:@"" replyToId:nil withDelegate:self];
    
}

- (void)sendShout:(NSData *)dataAudio withText:(NSString *)strText
{
    if (dataAudio)
    {
        if ([dataAudio length])
        {
            // don't let any sound come in until we have sent the shout
            [[STM audioSystem] holdActive:YES];
            
            [self showBusy:YES];
            
            //            self.strReplyToShoutID = [self replyToShoutID];
            
            // Wave Header information: http://www.topherlee.com/software/pcm-tut-wavformat.html
            // Ascii-Table: http://web.cs.mun.ca/~michael/c/ascii-table.html
            static unsigned char initialHeader[] = {
                0x52,0x49,0x46,0x46         // "RIFF", Marks the file as a riff file. Characters are each 1 byte long.
            };
            
            static unsigned char endHeader[] = {
                0x57,0x41,0x56,0x45,        // File Type Header. For our purposes, it always equals "WAVE".
                0x66,0x6D,0x74,0x20,        // Format chunk marker. Includes trailing null. "FMT "
                0x10,0x00,0x00,0x00,        // Length of format data as listed above. 16
                0x01,0x00,                  // Type of format (1 is PCM) - 2 byte integer. 1
                0x01,0x00,                  // Number of Channels - 2 byte integer. 1
                0x80,0x3E,0x00,0x00,        // Sample Rate - 32 byte integer. Common values are 44100 (CD), 48000 (DAT). Sample Rate = Number of Samples per second, or Hertz.
                0x00,0x7D,0x00,0x00,        // (Sample Rate * BitsPerSample * Channels) / 8.
                0x02,0x00,                  // (BitsPerSample * Channels) / 8.1 - 8 bit mono2 - 8 bit stereo/16 bit mono4 - 16 bit stereo
                0x10,0x00,                  // Bits per sample
                0x64,0x61,0x74,0x61         // "data" chunk header. Marks the beginning of the data section.
            };
            
            NSMutableData *data = [[NSMutableData alloc] init];
            
            // start with the initial wav file header
            [data appendBytes:(const void *)initialHeader length:sizeof(initialHeader)];
            
            // byte indicies 4-7 are the file size (http://www.topherlee.com/software/pcm-tut-wavformat.html)
            uint32_t fileSize = (uint32_t) [dataAudio length];
            fileSize += (uint32_t) 36;
            [data appendBytes:(const void *)&fileSize length:sizeof(uint32_t)];
            
            // add on the rest of the header
            [data appendBytes:(const void *)endHeader length:sizeof(endHeader)];
            
            // add the size of our data
            uint32_t dataSize = (uint32_t) [dataAudio length];
            [data appendBytes:(const void *)&dataSize length:sizeof(uint32_t)];
            
            // add the raw pcm data
            [data appendData:dataAudio];
            
            
            [[STM sendShout] sendData:data text:strText replyToId:nil tags:self.tags topic:self.topic withDelegate:self];
            
        }
    }
}

// brings up a view that blocks the screen and indicates the app is busy
- (void)showBusy:(BOOL)bShow
{
    if (bShow) {
        [self.indicator startAnimating];
    } else {
        [self.indicator stopAnimating];
    }
}

- (UIActivityIndicatorView *)indicator {
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    return _indicator;
}

// plays the given audio file and sets the command to be performed after it is done
- (void)playAudio:(NSString *)strAudioFile withAfterCmd:(tAfterAudioCmd)afterAudioCmd;
{
    [self stopPlayingAudio];
    [[STM audioSystem] playBundleFile:strAudioFile withDelegate:self.voiceCmdView andUserData:nil];
}

- (void)stopPlayingAudio
{
    [[STM audioSystem] stopAudioAndSpeechFor:self.voiceCmdView cancelCallback:YES];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)userRequestsStopListening {
    [self.voiceCmdView userRequestsStopListening];
}
#pragma mark - VoiceCmd View Delegates

// called when the voice command has completed
- (void)VoiceCmdView:(VoiceCmdView *)voiceCmdView completeWithResults:(VoiceCmdResults *)results
{
    self.voiceCmdResults = results;
    [self performSelector:@selector(processVoiceResults) withObject:nil afterDelay:0.0];
}

// processes the results of the voice command and issues the appropriate response
- (void)processVoiceResults
{
    self.bDismiss = YES;
    [self showBusy:YES];
    
    NSLog(@"Shout Audio Length: %lu", (unsigned long)self.voiceCmdResults.dataAudio.length);
    
    if (self.voiceCmdResults.dataAudio.length < MIN_AUDIO_LEN_AFTER_ERR) {
        self.voiceCmdResults.bUserClosed = YES;
    }
    
    if (self.voiceCmdResults.bUserClosed)
    {
        //[self stopPlayingAudioOrSpeaking];
        self.bDismiss = YES;
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        if ([self.delegate respondsToSelector:@selector(overlayClosed:)]) {
            [self.delegate overlayClosed:YES];
        }
    } else {
        self.bDismiss = YES;
        [self sendShout:self.voiceCmdResults.dataAudio withText:self.voiceCmdResults.strText];
    }
}

#pragma mark - SendShout Delegate

// called when a shout has finished sending to the user
- (void)onSendShoutCompleteWithStatus:(tSendShoutStatus)status
{
    // release our hold on the audio
    [[STM audioSystem] holdActive:NO];
    
    if (status == SendShoutStatus_Success)
    {
        [self playAudio:SHOUT_SENT_SOUND withAfterCmd:AfterAudioCmd_None];
        
    }
    if (self.bDismiss)
    {
        [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
        if ([self.delegate respondsToSelector:@selector(overlayClosed:)]) {
            [self.delegate overlayClosed:NO];
        }
    }
    [self showBusy:NO];
    
    NSLog(@"Shout sent %@", status == SendShoutStatus_Success ? @"successfully" : @"unsuccessfully");
}

- (void)onSendShoutCompleteWithShout:(STMShout *)shout WithStatus:(tSendShoutStatus)status {
    if ([self.delegate respondsToSelector:@selector(shoutCreated:error:)]) {
        if (status == SendShoutStatus_Success) {
            [self.delegate shoutCreated:shout error:nil];
        }
    }
}

- (void)VoiceCmdViewCloseButtonTouched:(VoiceCmdView *)voiceCmdView {
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
    if ([self.delegate respondsToSelector:@selector(overlayClosed:)]) {
        [self.delegate overlayClosed:YES];
    }
}



@end
