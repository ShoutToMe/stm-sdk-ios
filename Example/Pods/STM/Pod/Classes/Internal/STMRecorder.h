#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "STMVad.h"


@protocol STMRecorderDelegate;

//
// Handles recording of audio data using Audio Queue Services
//
@interface STMRecorder : NSObject <STMVadDelegate>
@property (atomic) id<STMRecorderDelegate> delegate;
@property (atomic) float power; // recording volume power

#pragma mark - Recording
-(BOOL)start;
-(BOOL)stop;
-(BOOL)isRecording;
-(BOOL)stoppedUsingVad;
-(void)enabledVad;
@end

@protocol STMRecorderDelegate <NSObject>

-(void)recorderDetectedSpeech;
-(void)recorderGotChunk:(NSData*)chunk;
-(void)recorderStarted;
-(void)recorderVadStoppedTalking;



-(void)stop;
@end