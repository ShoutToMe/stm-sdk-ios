#import <Foundation/Foundation.h>
#import <Accelerate/Accelerate.h>
#import "STMCvad.h"


@protocol STMVadDelegate;

@interface STMVad : NSObject

@property id<STMVadDelegate> delegate;

@property BOOL stoppedUsingVad;


-(void) gotAudioSamples:(NSData *)samples;

@end


@protocol STMVadDelegate <NSObject>

-(void) vadStartedTalking;
-(void) vadStoppedTalking;

@end